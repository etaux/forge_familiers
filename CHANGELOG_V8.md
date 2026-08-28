# Modifications V8.0 — Architecture 501 cartes

## Cible

- 100 communes
- 100 rares
- 100 épiques
- 100 légendaires
- 100 Uniques
- 1 Ultime

Le catalogue actuel contient 65 cartes. Il reste 436 cartes originales à produire en environ 44 lots.

## Collection

- Pagination de 12 cartes.
- Recherche et filtre avant instanciation graphique.
- Suppression des centaines de cartes UI au démarrage.
- Chargement des textures limité à la page visible.
- Compteur de résultats et navigation Précédente / Suivante.

## Fusion

- Pagination de 8 recettes.
- Recherche par nom et titre.
- Filtre par rareté fusionnable.
- Vérification globale du bouton Tout fusionner sans afficher toutes les recettes.
- Architecture prête pour 400 recettes finales.

## Base de données

- Index d’identifiants mis en cache par rareté.
- Tirages aléatoires sans parcourir tout le catalogue.
- Calcul rapide des taux individuels.

## Objectif Ultime

- Liste des Uniques requises paginée par 12.
- Progression et texte adaptés automatiquement au nombre d’Uniques.
- L’objectif passera automatiquement de 11 à 100 conditions lorsque le catalogue sera complet.

## Production

- Ajout de `data/catalog_target.json`.
- Ajout de `data/production_batches.csv`.
- Ajout de `docs/CATALOG_501_ARCHITECTURE.md`.
- Tests d’interface mis à jour pour vérifier les limites de composants par page.
