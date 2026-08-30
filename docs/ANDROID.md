# Sauvegarde locale + export APK

## 1. Supprimer la sauvegarde locale

Le jeu écrit un seul fichier :

`user://forge_familiers_save.json`

### Depuis l’éditeur Godot (le plus simple)

1. Ouvre le projet **Forge des Familiers**.
2. Menu **Projet → Ouvrir le dossier des données utilisateur**.
3. Supprime `forge_familiers_save.json`.
4. Relance le jeu : tu repars à zéro (2500 jetons, 200 essences).

### À la main, Windows

Éditeur Godot :

```
%APPDATA%\Godot\app_userdata\Forge des Familiers\forge_familiers_save.json
```

Jeu exporté Windows (`.exe`) :

```
%APPDATA%\Forge des Familiers\forge_familiers_save.json
```

Colle le chemin dans l’Explorateur (barre d’adresse) puis supprime le `.json`.

### Sur le téléphone (APK)

Le fichier est dans les données de l’app `fr.etaux.forgedesfamiliers`, pas accessible sans root.

- **Désinstalle** l’app, puis réinstalle l’APK.
- Le preset a `retain_data_on_uninstall=false` : la sauvegarde part avec l’app.

---

## 2. Erreur « chemin non valide pour le SDK Java… Dossier bin manquant »

Godot 4.7 veut **OpenJDK 17**. Le chemin doit pointer vers le dossier **qui contient** `bin`, pas vers `bin` lui-même.

### Ce qu’il faut installer

1. **OpenJDK 17** (Temurin) : https://adoptium.net/temurin/releases/?version=17  
   Windows x64 → MSI « JDK ».
2. **Android Studio** (pour le SDK Android) : https://developer.android.com/studio  
   Lance-le une fois, SDK Manager, installe au minimum :
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android SDK Platform 34 (ou plus récent)
   - Android SDK Command-line Tools
   - NDK + CMake (demandés par le build Gradle du projet)

### Chemins à coller dans Godot

**Éditeur → Paramètres de l’éditeur → Export → Android**

| Réglage | Bon chemin (exemple Windows) | Mauvais chemin |
|---|---|---|
| **Java SDK Path** | `C:\Program Files\Eclipse Adoptium\jdk-17.0.14+7` | `…\jdk-17\bin` |
| | ou `C:\Program Files\Android\Android Studio\jbr` | `C:\Program Files\Java` |
| **Android SDK Path** | `C:\Users\TON_NOM\AppData\Local\Android\Sdk` | le dossier Java |

Vérifie que **ce fichier existe** :

```
<Java SDK Path>\bin\java.exe
```

Si `bin` n’est pas **à l’intérieur** du dossier choisi, Godot affiche exactement ton erreur.

Astuces fréquentes :

- Enlève un `\bin` à la fin si tu l’as mis.
- Enlève les **guillemets** `"` si Windows les a collés avec le chemin.
- N’utilise pas un JRE, ni Java 8 / 11 / 21 : **JDK 17**.
- Le plus simple si Android Studio est installé :  
  `C:\Program Files\Android\Android Studio\jbr`

Le SDK Android, lui, doit contenir `platform-tools`, `build-tools` et `platforms`.

### Après les chemins

1. **Éditeur → Gérer les modèles d’export…** → télécharge les templates **4.7** (même version que l’éditeur).
2. Le preset Android du projet a **Use Gradle Build = on**.  
   **Projet → Installer le modèle de build Android…** (crée `android/build/` dans le projet).
3. **Projet → Exporter → Android**  
   - Debug keystore : laisse Godot le créer, ou **Éditeur → Paramètres → Export → Android → Debug Keystore**.
   - Fichier de sortie déjà prévu : `build/android/ForgeDesFamiliers.apk`
4. **Exporter le projet**.

Pour tester sur le téléphone : USB + débogage USB, ou copie l’APK et ouvre-le (sources inconnues autorisées).

Package : `fr.etaux.forgedesfamiliers`. Si une vieille version signée autrement est déjà installée, **désinstalle-la** d’abord.

Les presets incluent `data/*.json` (catalogue) et `assets/audio/*`. Sans ça, l’APK / l’exe démarre avec **0 carte**. Réexporte après toute modification de `export_presets.cfg`.
