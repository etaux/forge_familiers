#!/usr/bin/env python3
"""Frappe le serveur Phase B : session, ferme, caisse, fusion, marché, expédition."""
from __future__ import annotations

import json
import os
import sys
import threading
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
import server  # noqa: E402

BASE = "http://127.0.0.1:8787"


def req(method: str, path: str, body=None, token=None, idem=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if idem:
        headers["Idempotency-Key"] = idem
    request = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        return json.loads(exc.read().decode())


def main() -> int:
    os.environ.setdefault("FORGE_TEST", "1")
    if os.path.exists(server.DB_PATH):
        os.remove(server.DB_PATH)
    server.init_db()
    thread = threading.Thread(target=server.main, daemon=True)
    thread.start()
    time.sleep(0.4)

    health = req("GET", "/health")
    assert health["ok"] and health["cards"] == 313, health

    session = req("POST", "/v1/auth/session", {"device_id": "test-device"})
    assert session["ok"] and session["token"], session
    token = session["token"]

    farm = req("POST", "/v1/farm", {}, token, "farm-1")
    assert farm["ok"] and farm["amount"] == 2, farm
    again = req("POST", "/v1/farm", {}, token, "farm-1")
    assert again["amount"] == 2, "idempotence cassée"

    # Essence de départ 200 + 2. On crédite via une caisse petite.
    opened = req("POST", "/v1/crates/small/open", {}, token, "crate-1")
    assert opened["ok"] and len(opened["pulls"]) == 6, opened

    wallet = req("GET", "/v1/wallet", token=token)
    assert wallet["essence"] == 200 + 2 - 150, wallet
    assert wallet["currency"] == "COINS"

    inv = req("GET", "/v1/inventory", token=token)
    assert inv["ok"] and inv["inventory"], inv

    # Forcer un stock pour fusion / marché
    conn = server.db()
    conn.execute("UPDATE inventory SET available = 12 WHERE user_id=? AND card_id='mousselet'", (session["user_id"],))
    if conn.execute("SELECT 1 FROM inventory WHERE user_id=? AND card_id='mousselet'", (session["user_id"],)).fetchone() is None:
        conn.execute(
            "INSERT INTO inventory VALUES(?,?,12,0)", (session["user_id"], "mousselet")
        )
    conn.commit()
    conn.close()

    fused = req("POST", "/v1/fusions", {"card_id": "mousselet"}, token, "fuse-1")
    assert fused["ok"] and fused["spent"] == 10, fused

    listed = req("POST", "/v1/market/listings", {"card_id": "mousselet", "quantity": 1, "unit_price": 50}, token, "list-1")
    assert listed["ok"] and listed.get("listing_id"), listed

    other = req("POST", "/v1/auth/session", {"device_id": "buyer"})
    buy_token = other["token"]
    conn = server.db()
    conn.execute("UPDATE users SET coins = 5000 WHERE id=?", (other["user_id"],))
    conn.commit()
    conn.close()
    board = req("GET", "/v1/market/listings", token=buy_token)
    assert board["ok"] and any(row["id"] == listed["listing_id"] for row in board["listings"]), board
    assert any(row.get("is_mine") for row in req("GET", "/v1/market/listings", token=token)["listings"])
    bought = req("POST", "/v1/market/orders", {"listing_id": listed["listing_id"]}, buy_token, "buy-1")
    assert bought["ok"] and bought["currency"] == "COINS", bought
    assert bought["card_id"] == "mousselet" and bought["quantity"] == 1, bought
    assert bought["coins"] == 4950, bought
    synced = req("POST", "/v1/market/sync", {"coins": 3000, "cards": {"mousselet": 2}}, buy_token, "sync-1")
    assert synced["ok"] and synced["coins"] >= 4950, synced

    # Expédition courte
    conn = server.db()
    conn.execute(
        "INSERT OR REPLACE INTO inventory VALUES(?,?,3,0)", (session["user_id"], "bouliflore")
    )
    conn.commit()
    conn.close()
    started = req("POST", "/v1/expeditions", {"expedition_id": "short", "team": ["bouliflore"]}, token, "exp-1")
    assert started["ok"], started
    # Forcer la fin
    conn = server.db()
    conn.execute("UPDATE expeditions SET ends_at = 0 WHERE user_id=?", (session["user_id"],))
    conn.commit()
    conn.close()
    claimed = req("POST", "/v1/expeditions/claim", {}, token, "exp-claim")
    assert claimed["ok"] and claimed["reward"] == 50, claimed

    print("BACKEND SMOKE OK — Phase B jetons, pity, fusion ×10, marché, expédition.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
