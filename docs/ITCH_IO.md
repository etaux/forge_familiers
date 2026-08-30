# Publier Forge des Familiers sur itch.io

Itch n’accepte pas un projet Godot brut : il faut un **exécutable**.  
Export depuis **Godot 4.7** (ce sandbox n’a pas l’éditeur), puis upload du zip.

## 1. Préparer Godot

1. Ouvre le dossier `forge_familiers` dans Godot **4.7**.
2. `Éditeur → Gérer les modèles d’export…` → télécharge les templates **4.7**.
3. `Projet → Exporter…` : presets **Windows Desktop** et **Linux** déjà ajoutés.
   - PCK intégré (`embed_pck`) : un `.exe` (ou binaire Linux) + peu de fichiers.
   - Exclut backend, tests, docs, aperçus.
   - **Inclut** `data/*.json` (catalogue 313 cartes) et les sons : sans ça l’exe affiche 0 carte.

## 2. Exporter Windows (principal)

1. Preset **Windows Desktop**.
2. `Exporter le projet…`
3. Dossier vide, fichier `ForgeDesFamiliers.exe`.
4. Godot écrit par ex. :
   - `ForgeDesFamiliers.exe`
   - éventuellement `ForgeDesFamiliers.pck` si l’intégration PCK a sauté — laisse-le à côté.
5. Zippe **le contenu du dossier** (pas un sous-dossier) :
   - `ForgeDesFamiliers-windows.zip`

Même chose pour Linux si tu veux : `ForgeDesFamiliers-linux.zip`.

Ne zippe pas le projet source. Les joueurs ne doivent pas installer Godot.

## 3. Créer la page itch

1. https://itch.io/game/new (compte itch gratuit).
2. **Title** : `Forge des Familiers`
3. **Project URL** : `forge-des-familiers` (ou celui que itch propose).
4. **Classification** : `Games`
5. **Kind of project** : `Downloadable`
6. **Release status** : `In development` (prototype) ou `Prototype`
7. **Pricing** : `Free` (ou *pay what you want* — **pas d’argent réel dans le jeu**).
8. **Genre** : Card Game
9. **Tags** : `godot`, `collection`, `cards`, `idle`, `creatures`, `french`, `pixel-free`, `singleplayer`
10. **Platforms** : Windows (coche Linux si tu exportes Linux).
11. **Cover** : `assets/store/itch_cover.png` (630×500 environ).
12. **Banner** (optionnel) : `assets/store/itch_banner.png`.
13. Captures : captures Godot (Ferme, caisse, collection). Les `apercu_*.jpg` du dépôt peuvent servir.

Colle le texte ci-dessous dans **Description** (Markdown).

## 4. Uploader

1. `Upload files` → `ForgeDesFamiliers-windows.zip`.
2. Type of file : **Executable**.
3. Coche **This file will be played in the browser** : **non**.
4. Coche Windows (et Linux pour l’autre zip).
5. Save → **View page** → **Publish**.

Tu peux aussi utiliser [butler](https://itch.io/docs/butler/) plus tard pour les mises à jour.

## Texte à coller

### Courte phrase (tagline)

Collectionne 313 familiers. Récolte l’essence, ouvre des caisses, fusionne, restaure des habitats — sans argent réel.

### Description

```markdown
**Forge des Familiers** est un prototype de collection (Godot 4.7, portrait). Récolte de l’essence sur ta ferme, ouvre des caisses Origine, complète habitats et albums, fusionne les doublons et vise la carte ultime **AETERNUM**.

Le marché n’utilise que des **jetons de jeu**.

## Contenu actuel

- **313 cartes** (100 communes, 100 rares, 100 épiques, 1 légendaire, 11 uniques, 1 ultime)
- Quêtes de début + défis du jour
- Améliorations de ferme et légère fortune des caisses
- Pity affiché, fusion identique (×10 / ×10 / ×8 / ×5)
- Expéditions avec équipe en séquestre
- FR / EN (les noms de créatures restent tels quels)

## Contrôles

Souris ou tactile. Barre d’espace = récolter (page Ferme).

## Sauvegarde

Locale, sur la machine (`user://`). Pas de compte.

Prototype : l’économie et le catalogue évoluent encore.
```

### Avertissement / communauté

```text
Prototype hors-ligne. Aucun achat intégré.
```
