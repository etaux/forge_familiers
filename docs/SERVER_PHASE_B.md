# Serveur — jetons de jeu

Le téléphone ne décide pas des soldes. Le serveur gère comptes, inventaire, caisses, fusion et marché **en jetons de jeu**.

## Lancer

```bash
python3 backend/server.py
python3 backend/smoke_test.py
```

Écoute : `http://127.0.0.1:8787`. Base SQLite locale `backend/forge.sqlite` (ignorée par git).

## Auth

`POST /v1/auth/session` avec `{ "device_id": "…" }` crée ou reprend un compte et rend un jeton Bearer. Prototype : pas de mot de passe.

## API

| Méthode | Route | Rôle |
|---|---|---|
| POST | `/v1/auth/session` | session |
| GET | `/v1/me` | profil + pity + maîtrise |
| GET | `/v1/inventory` | quantités available / reserved |
| GET | `/v1/wallet` | essence, jetons, poussières |
| POST | `/v1/farm` | récolte manuelle |
| POST | `/v1/crates/{id}/open` | ouverture autoritaire + pity |
| POST | `/v1/fusions` | fusion d’identiques |
| GET | `/v1/market/listings` | offres actives (vendeur + `is_mine`) |
| POST | `/v1/market/sync` | aligne jetons (max) et cartes vendables |
| POST | `/v1/market/listings` | séquestre + offre |
| DELETE | `/v1/market/listings/{id}` | annulation vendeur |
| POST | `/v1/market/orders` | achat en jetons |
| POST | `/v1/expeditions` | équipe séquestrée |
| POST | `/v1/expeditions/claim` | récompense + maîtrise |

Toute mutation exige `Idempotency-Key`.

## Client Godot

Hors-ligne par défaut : le marché affiche des offres de démonstration.

Pour le marché multijoueur (jetons uniquement) :

1. Lancer `python3 backend/server.py` (écoute `0.0.0.0:8787`).
2. Dans le jeu : **Réglages** ou l’onglet **Marché** → Connecter.
3. Indiquer l’adresse (`http://127.0.0.1:8787` en local, ou `http://IP:8787` sur le réseau).

Le client envoie `device_id`, synchronise jetons/cartes vendables, puis liste / achète / annule via HTTP. Si le serveur est injoignable, le marché de démo local reste disponible.
