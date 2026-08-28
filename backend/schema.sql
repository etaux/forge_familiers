-- Schéma PostgreSQL de départ pour un marché autoritaire.
-- Prototype d’architecture : une revue sécurité/juridique reste indispensable.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE listing_status AS ENUM ('active', 'sold', 'cancelled', 'expired', 'frozen');
CREATE TYPE order_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded', 'disputed');
CREATE TYPE payment_status AS ENUM ('created', 'authorized', 'captured', 'failed', 'refunded', 'chargeback');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    public_name VARCHAR(32) NOT NULL UNIQUE,
    account_status VARCHAR(24) NOT NULL DEFAULT 'active',
    country_code CHAR(2),
    birth_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE card_definitions (
    card_id VARCHAR(64) PRIMARY KEY,
    rarity VARCHAR(16) NOT NULL CHECK (rarity IN ('common','rare','epic','legendary','unique')),
    catalog_version INTEGER NOT NULL,
    tradable BOOLEAN NOT NULL DEFAULT TRUE,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE inventories (
    user_id UUID NOT NULL REFERENCES users(id),
    card_id VARCHAR(64) NOT NULL REFERENCES card_definitions(card_id),
    available BIGINT NOT NULL DEFAULT 0 CHECK (available >= 0),
    reserved BIGINT NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    version BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, card_id)
);

CREATE TABLE wallets (
    user_id UUID NOT NULL REFERENCES users(id),
    currency VARCHAR(12) NOT NULL CHECK (currency IN ('COINS','EUR_CENTS')),
    available BIGINT NOT NULL DEFAULT 0 CHECK (available >= 0),
    reserved BIGINT NOT NULL DEFAULT 0 CHECK (reserved >= 0),
    version BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, currency)
);

CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID NOT NULL REFERENCES users(id),
    card_id VARCHAR(64) NOT NULL REFERENCES card_definitions(card_id),
    quantity BIGINT NOT NULL CHECK (quantity > 0),
    unit_price BIGINT NOT NULL CHECK (unit_price > 0),
    currency VARCHAR(12) NOT NULL CHECK (currency IN ('COINS','EUR_CENTS')),
    status listing_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ
);
CREATE INDEX listings_active_search ON listings (card_id, currency, unit_price, created_at)
    WHERE status = 'active';
CREATE INDEX listings_seller ON listings (seller_id, status, created_at DESC);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES listings(id),
    buyer_id UUID NOT NULL REFERENCES users(id),
    seller_id UUID NOT NULL REFERENCES users(id),
    card_id VARCHAR(64) NOT NULL REFERENCES card_definitions(card_id),
    quantity BIGINT NOT NULL CHECK (quantity > 0),
    gross_amount BIGINT NOT NULL CHECK (gross_amount > 0),
    fee_amount BIGINT NOT NULL DEFAULT 0 CHECK (fee_amount >= 0),
    currency VARCHAR(12) NOT NULL CHECK (currency IN ('COINS','EUR_CENTS')),
    status order_status NOT NULL DEFAULT 'pending',
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    CHECK (buyer_id <> seller_id),
    CHECK (fee_amount <= gross_amount)
);

CREATE TABLE wallet_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    currency VARCHAR(12) NOT NULL CHECK (currency IN ('COINS','EUR_CENTS')),
    delta BIGINT NOT NULL CHECK (delta <> 0),
    balance_after BIGINT NOT NULL CHECK (balance_after >= 0),
    operation VARCHAR(32) NOT NULL,
    reference_type VARCHAR(32) NOT NULL,
    reference_id UUID,
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX wallet_ledger_user_time ON wallet_ledger (user_id, created_at DESC);

CREATE TABLE inventory_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    card_id VARCHAR(64) NOT NULL REFERENCES card_definitions(card_id),
    delta_available BIGINT NOT NULL DEFAULT 0,
    delta_reserved BIGINT NOT NULL DEFAULT 0,
    available_after BIGINT NOT NULL CHECK (available_after >= 0),
    reserved_after BIGINT NOT NULL CHECK (reserved_after >= 0),
    operation VARCHAR(32) NOT NULL,
    reference_type VARCHAR(32) NOT NULL,
    reference_id UUID,
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (delta_available <> 0 OR delta_reserved <> 0)
);
CREATE INDEX inventory_ledger_user_time ON inventory_ledger (user_id, created_at DESC);

CREATE TABLE payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    provider VARCHAR(24) NOT NULL,
    provider_reference VARCHAR(128) UNIQUE,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    currency CHAR(3) NOT NULL DEFAULT 'EUR',
    status payment_status NOT NULL DEFAULT 'created',
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    receipt_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE webhook_events (
    provider VARCHAR(24) NOT NULL,
    provider_event_id VARCHAR(160) NOT NULL,
    payload JSONB NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    PRIMARY KEY (provider, provider_event_id)
);

-- Les achats, ventes, fusions et ouvertures doivent être exécutés dans une
-- transaction SQL avec SELECT ... FOR UPDATE sur inventaires, portefeuilles
-- et offres concernés. Le client Godot ne doit jamais écrire directement ici.
