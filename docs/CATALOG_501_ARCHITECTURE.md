# Architecture du catalogue de 501 cartes

## Cible validée

- 100 communes
- 100 rares
- 100 épiques
- 100 légendaires
- 100 Uniques
- 1 Ultime
- Total : 501 cartes

Les cartes existantes sont incluses dans ces nombres. **313 / 501** sont en catalogue (communes, rares et épiques complets). Il reste **188** cartes : 99 légendaires et 89 uniques, soit environ 19 lots de dix images.

## Choix artistiques

- Structure mixte : familles, lignées évolutives et créatures indépendantes.
- Une illustration réellement différente par carte.
- Aucun simple changement automatique de couleur ne compte comme nouvelle illustration.
- Les niveaux de détail et d’effets augmentent avec la rareté.

## Optimisations V8

### Collection paginée

La collection n’instancie plus toutes les cartes au démarrage.

- 12 cartes maximum chargées par page.
- Recherche effectuée sur les données, pas sur 501 composants graphiques.
- Filtrage par rareté avant création des cartes visuelles.
- Textures chargées uniquement pour la page visible.
- Boutons Précédente et Suivante.

Avec 501 cartes, la collection utilisera 42 pages au maximum au lieu de créer 501 cartes graphiques simultanément.

### Fusion paginée

- 8 recettes maximum affichées par page.
- Recherche par nom ou titre.
- Filtre Commune / Rare / Épique / Légendaire.
- Le bouton Tout fusionner vérifie le catalogue complet sans construire toutes les lignes.
- En cible finale, 400 recettes sont gérées en 50 pages.

### Cache de rareté

`CardDatabase` maintient un index d’identifiants par rareté.

- Tirage aléatoire sans parcourir les 501 cartes.
- Calcul du taux individuel à partir du nombre de cartes du rang.
- Accès rapide aux listes d’une rareté.

### Objectif Ultime

L’objectif AETERNUM s’adapte automatiquement au nombre d’Uniques.

- Actuellement : 11 Uniques nécessaires (AETERNUM).
- Cible finale : 100 Uniques nécessaires. Le pity Unique (8 000 cartes) doit rester en place avant d’élargir le rang.
- Les cartes requises sont affichées par pages de 12.
- Aucune grille de 100 textures n’est créée d’un seul coup.

## Taux individuels à 100 cartes par rang

| Rareté | Taux du rang | Taux d’une carte précise |
|---|---:|---:|
| Commune | 89,39 % | 0,8939 % |
| Rare | 10 % | 0,1 % |
| Épique | 0,5 % | 0,005 % |
| Légendaire | 0,1 % | 0,001 % |
| Unique | 0,01 % | 0,0001 % |
| Ultime | 0 % | Objectif uniquement |

## Organisation mixte recommandée

Pour chaque rang de 100 cartes :

- 40 cartes dans des familles de créatures ;
- 30 cartes dans des lignées évolutives ;
- 30 créatures indépendantes ou événementielles.

Les chiffres peuvent varier par rareté, mais chaque carte conserve un identifiant permanent et une illustration originale.

## Ordre de production

1. ~~Communes 100/100~~
2. ~~Rares 100/100~~
3. ~~Épiques 100/100~~
4. Produire les 99 légendaires manquantes.
5. Produire les 89 Uniques manquantes (après validation du pity).
6. Étendre progressivement les habitats et albums.

L’état chiffré est conservé dans `data/catalog_target.json`.
