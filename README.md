# Forge des Familiers

Prototype mobile Godot 4.7 d’un jeu de **collection de créatures**.  
Série Origine : **313 / 501 cartes** (100 communes, 100 rares, 100 épiques, 1 légendaire, 11 uniques, 1 ultime).

Le joueur récolte de l’essence dans sa ferme, ouvre des caisses, complète habitats et albums, fusionne des doublons identiques, envoie des expéditions et vise la carte ultime **AETERNUM**.

> Le marché n’utilise que des **jetons de jeu**, gagnés en jouant.

## Lancer le prototype

1. Godot **4.7** (rendu GL Compatibility).
2. Ouvrir ce dossier, scène principale `scenes/main.tscn`.
3. Viewport logique : **540 × 960**, portrait.

```text
Ferme → Cartes → Albums → Fusion → Marché
```

Tests (depuis l’éditeur, scènes `tests/*.tscn`) :

- `tests/smoke_test.tscn` — économie, pity, fusion, expéditions, habitats
- `tests/ui_flow_test.tscn` — pagination, overlays, révélation

Audit catalogue :

```bash
python3 tools/catalog_audit.py
```

## Boucle de jeu

| Session | Actions |
|---|---|
| 30 s – 3 min | Récolter, ouvrir 1 caisse, missions du jour |
| 5 – 15 min | Composer une expédition, fusionner, consulter un album |
| Long terme | 7 habitats, 60 albums, 11 uniques → forger AETERNUM |

**Ferme.** Paysage vivant : les créatures découvertes s’y promènent. Récolte manuelle +2 essences / 10 s, passif +1 / 10 s, hors-ligne plafonné à 8 h.

**Caisses Origine.** 6 / 15 / 25 / 50 cartes pour 150 / 330 / 500 / 850 essences. Taux affichés sur chaque carte.

**Pity.** Filet anti-malchance (voir `docs/PITY.md`) : une rare au plus tard toutes les 20 cartes, une unique au plus tard toutes les 8 000.

**Fusion.** Exemplaires **identiques** uniquement : ×10 commune → rare, ×10 rare → épique, ×8 épique → légendaire, ×5 légendaire → unique.

**Expéditions.** Le joueur choisit l’équipe (1 / 3 / 5 créatures). Elles sont **séquestrées** jusqu’au retour et gagnent de la **maîtrise**.

**Habitats.** Bonus d’expédition proportionnel à la taille (Forêt +6 %, Rivages +9 %, Archive chromatique +10 %).

## Architecture

```text
scripts/card_database.gd   catalogue, taux, fusions
scripts/game_state.gd      économie locale, save v5
scripts/server_api.gd      client HTTP Phase B (jetons)
scripts/main.gd            coque : header, nav, tutoriel
scripts/ui/ui_kit.gd       design system
scripts/pages/*.gd         Ferme, Cartes, Albums, Fusion, Marché
scripts/ui/overlay_host.gd overlays (missions, caisse, équipe…)
backend/server.py          inventaire autoritaire, marché jetons
```

Données : `data/card_catalog.json`, `data/collections.json`.  
Sauvegarde joueur : `user://forge_familiers_save.json` (version 5).

## Serveur Phase B

Marché et mutations sensibles sont conçus pour un serveur autoritaire, toujours en jetons de jeu. Le client reste jouable hors-ligne.

```bash
python3 backend/server.py
# écoute http://127.0.0.1:8787
python3 backend/smoke_test.py
```

Voir `docs/MARKETPLACE_ARCHITECTURE.md` et `docs/SERVER_PHASE_B.md`.

## Export Android

Préset `Android` dans `export_presets.cfg` :

- package `fr.etaux.forgedesfamiliers`
- orientation portrait
- architectures `arm64-v8a` + `armeabi-v7a`

Un SDK Android + un keystore restent nécessaires pour un APK signé.

## Licence

MIT — voir `LICENSE`. Police Nunito : SIL OFL (`assets/fonts/OFL.txt`).
