# Modifications V4

## Recyclage

- Nouvelle monnaie : poussières.
- Valeurs de recyclage par rareté : 1 / 25 / 250 / 2 500 / 10 000.
- Le premier exemplaire de chaque carte est automatiquement protégé.
- Fenêtre de sélection de quantité et aperçu du rendement.
- Invocation d’une commune manquante contre 100 poussières.

## Collection permanente

- Ajout d’un registre permanent des cartes découvertes.
- Une carte reste visible et compte dans les ensembles même lorsque l’inventaire tombe à zéro.
- Migration automatique des anciennes découvertes à partir de l’inventaire V3.

## Habitats

- Six habitats couvrant les 54 cartes exactement une fois.
- Progression et récompense propres à chaque habitat.
- +5 % aux récompenses d’expédition par habitat restauré.
- Bonus maximum actuel : +30 %.

## Albums

- Huit albums thématiques de six cartes.
- Récompenses uniques en essence, jetons et poussières.
- Affichage des cartes encore manquantes.
- Données externalisées dans `data/collections.json`.

## Interface

- Nouvel onglet Albums.
- Navigation portée à cinq onglets.
- Ajout des actions Recycler et Invoquer.
- Affichage du solde de poussières et du bonus d’expédition.

## Qualité

- Sauvegarde portée en version 4.
- Aucune nouvelle remise à zéro de l’essence lors de la migration V3 vers V4.
- Tests de logique et d’interface V4 validés sous Godot 4.7.2.
