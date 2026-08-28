# Design system mobile V6

## Typographie

Police : **Nunito Variable**, intégrée dans `assets/fonts/` sous licence SIL Open Font License.

| Usage | Taille cible | Graisse |
|---|---:|---:|
| Micro-information | 11–12 px | 500–650 |
| Corps et descriptions | 13–14 px | 500–650 |
| Boutons | 12–14 px | 750 |
| Sous-titres | 15–18 px | 750 |
| Titres de page | 24–28 px | 900 |

Le rendu MSDF utilise une source de 64 px et une plage de 12 px. Les contours de texte restent limités à 2 ou 3 px.

## Résolution

- Viewport logique : 540 × 960.
- Fenêtre de test : 540 × 960.
- Orientation : portrait.
- Mode d’étirement : `canvas_items`.
- HiDPI : activé.
- Contrôles alignés sur les pixels : activé.

## Palette

| Token | Couleur |
|---|---|
| Fond principal | `#060918` |
| Surface | `#0D1530` |
| Surface claire | `#162044` |
| Texte principal | `#F7F9FF` |
| Texte secondaire | `#AAB4CC` |
| Violet principal | `#8D70FF` |
| Cyan | `#62E4FF` |
| Or | `#FFD36A` |
| Vert | `#76E5AC` |

## Couleurs de navigation

- Ferme : cyan.
- Cartes : bleu.
- Albums : or.
- Fusion : violet.
- Marché : orange.

## Composants

### Bouton principal

- Hauteur conseillée : 52–66 px.
- Rayon : 18 px.
- Bordure : 2 px.
- Ombre verticale : 3–5 px.
- Texte Bold, minimum 12 px.

### Surface

- Rayon principal : 26–30 px.
- Fond opaque à 97–100 %.
- Bordure lumineuse faible.
- Ombre noire diffuse.

### Navigation

- Hauteur : 84 px.
- Icône et libellé sur deux lignes.
- Indicateur inférieur de 4 px sur l’onglet actif.
- Zone tactile d’au moins 68 px de haut.

### Fenêtre modale

- Largeur maximale : 456 px.
- Rayon : 30 px.
- Marge interne : 20 px.
- Fond d’écran assombri à 93 %.

## Accessibilité

- Aucun texte fonctionnel sous 11 px.
- Contraste élevé pour les informations importantes.
- Le statut ne repose pas uniquement sur une couleur : textes et quantités restent visibles.
- Les contrôles tactiles importants dépassent 48 px de hauteur.
