# Modifications V24.0 — recalage, pity, ferme, serveur Phase B

## Catalogue

- Docs et tests alignés sur **313 cartes** et **60 albums**.
- 100 communes, 100 rares, **100 épiques**, 1 légendaire, 11 uniques, 1 ultime.
- `catalog_target.json` et `production_batches.csv` à jour (188 cartes restantes).
- README réel.

## Pity

- Rare au plus tard toutes les 20 cartes, épique 300, légendaire 1 000, unique 8 000.
- Compteurs persistés (save v5), affichés sur l’écran Ferme.

## Fusion et habitats

- Coûts : commune ×10, rare ×10, épique ×8, légendaire ×5.
- Bonus d’habitat proportionnel à la taille (Rivages +9 %, Braises +3 %, Archive +10 %).

## Expéditions

- Équipe choisie par le joueur.
- Séquestre jusqu’au retour.
- Maîtrise individuelle (paliers 1 / 3 / 10 / 25) : +2 % de récompense par niveau.

## Interface

- `main.gd` réduit à la coque. Pages : `FarmPage`, `CollectionPage`, `AlbumsPage`, `FusionPage`, `MarketPage`.
- Overlays extraits dans `OverlayHost`.
- Design system `UIKit`.
- Ferme dessinée (ciel, collines, familiers, orbes de récolte).
- Tutoriel 5 étapes (~60 s).
- SFX (récolte, caisse, fusion, rareté).

## Technique

- `.gitignore` Godot, `.godot/` retiré du dépôt.
- Export Android `fr.etaux.forgedesfamiliers`.
- Serveur (`backend/server.py`) : jetons de jeu, idempotence, marché, caisses, fusion, expéditions.
- Marché limité aux jetons de jeu (plus aucune mention d’achat hors jeu).
- Save version 5 : pity, reserved, maîtrise, tutoriel.
