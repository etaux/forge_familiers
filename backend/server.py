#!/usr/bin/env python3
"""Serveur Phase B — inventaire autoritaire, caisses, fusion, marché en jetons."""
from __future__ import annotations

import json
import os
import random
import sqlite3
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

ROOT = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(ROOT, "forge.sqlite")
CATALOG_PATH = os.path.join(ROOT, "..", "data", "card_catalog.json")
HOST, PORT = "0.0.0.0", 8787

CRATES = {
    "small": {"cards": 6, "cost": 150},
    "medium": {"cards": 15, "cost": 330},
    "large": {"cards": 25, "cost": 500},
    "titan": {"cards": 50, "cost": 850},
}
FUSION_COSTS = {"common": 10, "rare": 10, "epic": 8, "legendary": 5}
PITY_CAPS = {"rare": 20, "epic": 300, "legendary": 1000, "unique": 8000}
PITY_ORDER = ["unique", "legendary", "epic", "rare"]
RARITY_ORDER = ["common", "rare", "epic", "legendary", "unique", "ultimate"]
STARTING_ESSENCE = 200
STARTING_COINS = 2500
FARM_REWARD = 2
FARM_COOLDOWN = 10
EXPEDITIONS = {
    "short": {"duration": 30 * 60, "reward": 50, "cards": 1},
    "medium": {"duration": 2 * 60 * 60, "reward": 180, "cards": 3},
    "long": {"duration": 8 * 60 * 60, "reward": 500, "cards": 5},
}

CATALOG = json.loads(open(CATALOG_PATH, encoding="utf-8").read())
CARDS = {c["id"]: c for c in CATALOG}
BY_RARITY: dict[str, list[str]] = {r: [] for r in RARITY_ORDER}
for card in CATALOG:
    BY_RARITY.setdefault(card["rarity"], []).append(card["id"])


def db() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")
    return conn


def init_db() -> None:
    conn = db()
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            public_name TEXT UNIQUE NOT NULL,
            device_id TEXT UNIQUE NOT NULL,
            token TEXT UNIQUE NOT NULL,
            essence INTEGER NOT NULL DEFAULT 200,
            coins INTEGER NOT NULL DEFAULT 2500,
            dust INTEGER NOT NULL DEFAULT 0,
            next_farm_at INTEGER NOT NULL DEFAULT 0,
            pity_rare INTEGER NOT NULL DEFAULT 0,
            pity_epic INTEGER NOT NULL DEFAULT 0,
            pity_legendary INTEGER NOT NULL DEFAULT 0,
            pity_unique INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS inventory (
            user_id TEXT NOT NULL,
            card_id TEXT NOT NULL,
            available INTEGER NOT NULL DEFAULT 0,
            reserved INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, card_id)
        );
        CREATE TABLE IF NOT EXISTS listings (
            id TEXT PRIMARY KEY,
            seller_id TEXT NOT NULL,
            card_id TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            created_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS idempotency (
            key TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            body TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS expeditions (
            user_id TEXT PRIMARY KEY,
            expedition_id TEXT NOT NULL,
            team TEXT NOT NULL,
            reward INTEGER NOT NULL,
            ends_at INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS mastery (
            user_id TEXT NOT NULL,
            card_id TEXT NOT NULL,
            xp INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (user_id, card_id)
        );
        CREATE TABLE IF NOT EXISTS wallet_ledger (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            currency TEXT NOT NULL,
            delta INTEGER NOT NULL,
            operation TEXT NOT NULL,
            created_at INTEGER NOT NULL
        );
        """
    )
    conn.commit()
    conn.close()


def json_body(handler: BaseHTTPRequestHandler) -> dict:
    length = int(handler.headers.get("Content-Length", 0))
    if length <= 0:
        return {}
    raw = handler.rfile.read(length)
    try:
        data = json.loads(raw.decode("utf-8"))
        return data if isinstance(data, dict) else {}
    except json.JSONDecodeError:
        return {}


def send(handler: BaseHTTPRequestHandler, code: int, payload: dict) -> None:
    blob = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(code)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type, Idempotency-Key")
    handler.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
    handler.send_header("Content-Length", str(len(blob)))
    handler.end_headers()
    handler.wfile.write(blob)


def user_from(handler: BaseHTTPRequestHandler, conn: sqlite3.Connection):
    auth = handler.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None
    token = auth[7:].strip()
    return conn.execute("SELECT * FROM users WHERE token = ?", (token,)).fetchone()


def inventory_of(conn, user_id: str) -> dict[str, dict]:
    rows = conn.execute(
        "SELECT card_id, available, reserved FROM inventory WHERE user_id = ?", (user_id,)
    ).fetchall()
    return {r["card_id"]: {"available": r["available"], "reserved": r["reserved"]} for r in rows}


def add_card(conn, user_id: str, card_id: str, amount: int = 1) -> None:
    conn.execute(
        """INSERT INTO inventory(user_id, card_id, available, reserved)
           VALUES(?,?,?,0)
           ON CONFLICT(user_id, card_id) DO UPDATE SET available = available + excluded.available""",
        (user_id, card_id, amount),
    )


def roll_rarity(rng: random.Random, pity: dict) -> tuple[str, bool]:
    for rarity in PITY_ORDER:
        if pity[rarity] >= PITY_CAPS[rarity]:
            return rarity, True
    roll = rng.random()
    if roll < 0.0001:
        rarity = "unique"
    elif roll < 0.0011:
        rarity = "legendary"
    elif roll < 0.0061:
        rarity = "epic"
    elif roll < 0.1061:
        rarity = "rare"
    else:
        rarity = "common"
    return rarity, False


def register_pity(pity: dict, rarity: str) -> None:
    for key in PITY_CAPS:
        pity[key] = 0 if key == rarity else pity[key] + 1


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[forge]", fmt % args)

    def do_OPTIONS(self):
        send(self, 204, {})

    def do_GET(self):
        path = urlparse(self.path).path
        conn = db()
        try:
            if path == "/health":
                return send(self, 200, {"ok": True, "cards": len(CARDS), "phase": "B"})
            user = user_from(self, conn)
            if user is None:
                return send(self, 401, {"ok": False, "error": "session requise"})
            if path == "/v1/me":
                return send(self, 200, {
                    "ok": True,
                    "user_id": user["id"],
                    "public_name": user["public_name"],
                    "pity": {
                        "rare": user["pity_rare"],
                        "epic": user["pity_epic"],
                        "legendary": user["pity_legendary"],
                        "unique": user["pity_unique"],
                    },
                })
            if path == "/v1/wallet":
                return send(self, 200, {
                    "ok": True,
                    "essence": user["essence"],
                    "coins": user["coins"],
                    "dust": user["dust"],
                    "currency": "COINS",
                })
            if path == "/v1/inventory":
                return send(self, 200, {"ok": True, "inventory": inventory_of(conn, user["id"])})
            if path == "/v1/market/listings":
                rows = conn.execute(
                    """SELECT l.id, l.seller_id, l.card_id, l.quantity, l.unit_price, l.status, l.created_at,
                              u.public_name AS seller
                       FROM listings l JOIN users u ON u.id = l.seller_id
                       WHERE l.status='active' ORDER BY l.created_at DESC LIMIT 80"""
                ).fetchall()
                listings = []
                for row in rows:
                    item = dict(row)
                    item["is_mine"] = item["seller_id"] == user["id"]
                    listings.append(item)
                return send(self, 200, {"ok": True, "listings": listings, "you": user["public_name"]})
            return send(self, 404, {"ok": False, "error": "route inconnue"})
        finally:
            conn.close()

    def do_DELETE(self):
        path = urlparse(self.path).path
        conn = db()
        try:
            user = user_from(self, conn)
            if user is None:
                return send(self, 401, {"ok": False, "error": "session requise"})
            if path.startswith("/v1/market/listings/"):
                listing_id = path.rsplit("/", 1)[-1]
                conn.execute("BEGIN IMMEDIATE")
                row = conn.execute("SELECT * FROM listings WHERE id = ?", (listing_id,)).fetchone()
                if row is None or row["status"] != "active":
                    return send(self, 404, {"ok": False, "error": "offre introuvable"})
                if row["seller_id"] != user["id"]:
                    return send(self, 403, {"ok": False, "error": "pas votre offre"})
                add_card(conn, user["id"], row["card_id"], row["quantity"])
                conn.execute("UPDATE listings SET status='cancelled' WHERE id = ?", (listing_id,))
                conn.commit()
                return send(self, 200, {"ok": True})
            return send(self, 404, {"ok": False, "error": "route inconnue"})
        finally:
            conn.close()

    def do_POST(self):
        path = urlparse(self.path).path
        body = json_body(self)
        conn = db()
        try:
            if path == "/v1/auth/session":
                device_id = str(body.get("device_id") or uuid.uuid4())
                row = conn.execute("SELECT * FROM users WHERE device_id = ?", (device_id,)).fetchone()
                if row is None:
                    user_id = str(uuid.uuid4())
                    token = uuid.uuid4().hex
                    name = "Forgeur#" + token[:4].upper()
                    conn.execute(
                        "INSERT INTO users(id, public_name, device_id, token, essence, coins, created_at) VALUES(?,?,?,?,?,?,?)",
                        (user_id, name, device_id, token, STARTING_ESSENCE, STARTING_COINS, int(time.time())),
                    )
                    conn.commit()
                    row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
                return send(self, 200, {
                    "ok": True,
                    "user_id": row["id"],
                    "token": row["token"],
                    "public_name": row["public_name"],
                })

            user = user_from(self, conn)
            if user is None:
                return send(self, 401, {"ok": False, "error": "session requise"})
            idem = self.headers.get("Idempotency-Key", "")
            if idem:
                cached = conn.execute(
                    "SELECT body FROM idempotency WHERE key = ? AND user_id = ?", (idem, user["id"])
                ).fetchone()
                if cached:
                    return send(self, 200, json.loads(cached["body"]))

            if path == "/v1/farm":
                now = int(time.time())
                if now < user["next_farm_at"]:
                    return send(self, 400, {"ok": False, "error": "recharge", "remaining": user["next_farm_at"] - now})
                conn.execute(
                    "UPDATE users SET essence = essence + ?, next_farm_at = ? WHERE id = ?",
                    (FARM_REWARD, now + FARM_COOLDOWN, user["id"]),
                )
                conn.execute(
                    "INSERT INTO wallet_ledger VALUES(?,?,?,?,?,?)",
                    (str(uuid.uuid4()), user["id"], "ESSENCE", FARM_REWARD, "farm", now),
                )
                conn.commit()
                payload = {"ok": True, "amount": FARM_REWARD, "essence": user["essence"] + FARM_REWARD}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path.startswith("/v1/crates/") and path.endswith("/open"):
                crate_id = path.split("/")[3]
                if crate_id not in CRATES:
                    return send(self, 400, {"ok": False, "error": "caisse inconnue"})
                crate = CRATES[crate_id]
                if user["essence"] < crate["cost"]:
                    return send(self, 400, {"ok": False, "error": "essence insuffisante"})
                pity = {
                    "rare": user["pity_rare"],
                    "epic": user["pity_epic"],
                    "legendary": user["pity_legendary"],
                    "unique": user["pity_unique"],
                }
                rng = random.Random()
                pulls = []
                pity_hits = []
                for _ in range(crate["cards"]):
                    rarity, hit = roll_rarity(rng, pity)
                    register_pity(pity, rarity)
                    if hit:
                        pity_hits.append(rarity)
                    pool = BY_RARITY.get(rarity) or BY_RARITY["common"]
                    card_id = pool[rng.randrange(len(pool))]
                    add_card(conn, user["id"], card_id, 1)
                    pulls.append(card_id)
                conn.execute(
                    """UPDATE users SET essence = essence - ?,
                       pity_rare=?, pity_epic=?, pity_legendary=?, pity_unique=? WHERE id=?""",
                    (crate["cost"], pity["rare"], pity["epic"], pity["legendary"], pity["unique"], user["id"]),
                )
                conn.commit()
                payload = {"ok": True, "pulls": pulls, "pity_hits": pity_hits, "amount": len(pulls)}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/fusions":
                card_id = str(body.get("card_id", ""))
                card = CARDS.get(card_id)
                if not card:
                    return send(self, 400, {"ok": False, "error": "carte inconnue"})
                cost = FUSION_COSTS.get(card["rarity"], 0)
                nxt = {"common": "rare", "rare": "epic", "epic": "legendary", "legendary": "unique"}.get(card["rarity"])
                if not nxt or cost <= 0:
                    return send(self, 400, {"ok": False, "error": "non fusionnable"})
                inv = conn.execute(
                    "SELECT available FROM inventory WHERE user_id=? AND card_id=?", (user["id"], card_id)
                ).fetchone()
                available = inv["available"] if inv else 0
                if available < cost:
                    return send(self, 400, {"ok": False, "error": "exemplaires insuffisants"})
                conn.execute(
                    "UPDATE inventory SET available = available - ? WHERE user_id=? AND card_id=?",
                    (cost, user["id"], card_id),
                )
                target = BY_RARITY[nxt][random.randrange(len(BY_RARITY[nxt]))]
                add_card(conn, user["id"], target, 1)
                conn.commit()
                payload = {"ok": True, "spent": cost, "card_id": target}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/market/sync":
                coins = max(max(0, int(body.get("coins", user["coins"]))), int(user["coins"]))
                cards = body.get("cards", {})
                if not isinstance(cards, dict):
                    return send(self, 400, {"ok": False, "error": "inventaire invalide"})
                conn.execute("BEGIN IMMEDIATE")
                conn.execute("UPDATE users SET coins = ? WHERE id = ?", (coins, user["id"]))
                known = set()
                for raw_id, raw_qty in cards.items():
                    card_id = str(raw_id)
                    if card_id not in CARDS:
                        continue
                    qty = max(0, int(raw_qty))
                    known.add(card_id)
                    conn.execute(
                        """INSERT INTO inventory(user_id, card_id, available, reserved)
                           VALUES(?,?,?,0)
                           ON CONFLICT(user_id, card_id) DO UPDATE SET available = excluded.available""",
                        (user["id"], card_id, qty),
                    )
                for row in conn.execute(
                    "SELECT card_id FROM inventory WHERE user_id=? AND reserved=0", (user["id"],)
                ).fetchall():
                    if row["card_id"] not in known:
                        conn.execute(
                            "UPDATE inventory SET available=0 WHERE user_id=? AND card_id=?",
                            (user["id"], row["card_id"]),
                        )
                conn.commit()
                payload = {"ok": True, "coins": coins, "public_name": user["public_name"]}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/market/listings":
                card_id = str(body.get("card_id", ""))
                quantity = int(body.get("quantity", 0))
                price = int(body.get("unit_price", 0))
                card = CARDS.get(card_id)
                if not card or quantity <= 0 or price <= 0:
                    return send(self, 400, {"ok": False, "error": "requête invalide"})
                if card.get("tradable") is False or card["rarity"] == "ultimate":
                    return send(self, 400, {"ok": False, "error": "carte non vendable"})
                conn.execute("BEGIN IMMEDIATE")
                inv = conn.execute(
                    "SELECT available FROM inventory WHERE user_id=? AND card_id=?", (user["id"], card_id)
                ).fetchone()
                if not inv or inv["available"] < quantity:
                    conn.rollback()
                    return send(self, 400, {"ok": False, "error": "stock insuffisant"})
                conn.execute(
                    "UPDATE inventory SET available = available - ? WHERE user_id=? AND card_id=?",
                    (quantity, user["id"], card_id),
                )
                listing_id = str(uuid.uuid4())
                conn.execute(
                    "INSERT INTO listings VALUES(?,?,?,?,?,'active',?)",
                    (listing_id, user["id"], card_id, quantity, price, int(time.time())),
                )
                conn.commit()
                payload = {
                    "ok": True,
                    "listing_id": listing_id,
                    "listing": {
                        "id": listing_id,
                        "seller": user["public_name"],
                        "card_id": card_id,
                        "quantity": quantity,
                        "unit_price": price,
                        "is_mine": True,
                    },
                }
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/market/orders":
                listing_id = str(body.get("listing_id", ""))
                conn.execute("BEGIN IMMEDIATE")
                listing = conn.execute("SELECT * FROM listings WHERE id=? AND status='active'", (listing_id,)).fetchone()
                if listing is None:
                    conn.rollback()
                    return send(self, 404, {"ok": False, "error": "offre indisponible"})
                if listing["seller_id"] == user["id"]:
                    conn.rollback()
                    return send(self, 400, {"ok": False, "error": "votre offre"})
                total = listing["quantity"] * listing["unit_price"]
                buyer = conn.execute("SELECT coins FROM users WHERE id=?", (user["id"],)).fetchone()
                if buyer["coins"] < total:
                    conn.rollback()
                    return send(self, 400, {"ok": False, "error": "jetons insuffisants"})
                conn.execute("UPDATE users SET coins = coins - ? WHERE id=?", (total, user["id"]))
                conn.execute("UPDATE users SET coins = coins + ? WHERE id=?", (total, listing["seller_id"]))
                add_card(conn, user["id"], listing["card_id"], listing["quantity"])
                conn.execute("UPDATE listings SET status='sold' WHERE id=?", (listing_id,))
                conn.commit()
                payload = {
                    "ok": True,
                    "total": total,
                    "currency": "COINS",
                    "card_id": listing["card_id"],
                    "quantity": listing["quantity"],
                    "coins": buyer["coins"] - total,
                }
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/expeditions":
                expedition_id = str(body.get("expedition_id", ""))
                team = list(body.get("team") or [])
                spec = EXPEDITIONS.get(expedition_id)
                if not spec:
                    return send(self, 400, {"ok": False, "error": "expédition inconnue"})
                if len(set(team)) != spec["cards"]:
                    return send(self, 400, {"ok": False, "error": "équipe invalide"})
                existing = conn.execute("SELECT * FROM expeditions WHERE user_id=?", (user["id"],)).fetchone()
                if existing:
                    return send(self, 400, {"ok": False, "error": "déjà en cours"})
                for card_id in team:
                    inv = conn.execute(
                        "SELECT available FROM inventory WHERE user_id=? AND card_id=?", (user["id"], card_id)
                    ).fetchone()
                    if not inv or inv["available"] < 1:
                        return send(self, 400, {"ok": False, "error": f"{card_id} indisponible"})
                    conn.execute(
                        "UPDATE inventory SET available=available-1, reserved=reserved+1 WHERE user_id=? AND card_id=?",
                        (user["id"], card_id),
                    )
                ends = int(time.time()) + spec["duration"]
                conn.execute(
                    "INSERT INTO expeditions VALUES(?,?,?,?,?)",
                    (user["id"], expedition_id, json.dumps(team), spec["reward"], ends),
                )
                conn.commit()
                payload = {"ok": True, "ends_at": ends, "reward": spec["reward"]}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            if path == "/v1/expeditions/claim":
                row = conn.execute("SELECT * FROM expeditions WHERE user_id=?", (user["id"],)).fetchone()
                if row is None:
                    return send(self, 400, {"ok": False, "error": "aucune expédition"})
                if int(time.time()) < row["ends_at"]:
                    return send(self, 400, {"ok": False, "error": "pas encore terminée"})
                team = json.loads(row["team"])
                for card_id in team:
                    conn.execute(
                        "UPDATE inventory SET available=available+1, reserved=reserved-1 WHERE user_id=? AND card_id=?",
                        (user["id"], card_id),
                    )
                    conn.execute(
                        """INSERT INTO mastery(user_id, card_id, xp) VALUES(?,?,1)
                           ON CONFLICT(user_id, card_id) DO UPDATE SET xp = xp + 1""",
                        (user["id"], card_id),
                    )
                conn.execute("UPDATE users SET essence = essence + ? WHERE id=?", (row["reward"], user["id"]))
                conn.execute("DELETE FROM expeditions WHERE user_id=?", (user["id"],))
                conn.commit()
                payload = {"ok": True, "reward": row["reward"]}
                self._store_idem(conn, idem, user["id"], payload)
                return send(self, 200, payload)

            return send(self, 404, {"ok": False, "error": "route inconnue"})
        finally:
            conn.close()

    def _store_idem(self, conn, key: str, user_id: str, payload: dict) -> None:
        if not key:
            return
        conn.execute(
            "INSERT OR REPLACE INTO idempotency(key, user_id, body) VALUES(?,?,?)",
            (key, user_id, json.dumps(payload)),
        )
        conn.commit()


def main() -> None:
    init_db()
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Forge Phase B sur http://{HOST}:{PORT}  ({len(CARDS)} cartes)")
    server.serve_forever()


if __name__ == "__main__":
    main()
