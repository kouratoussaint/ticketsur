# Application mobile TicketSûr (Flutter, Android d'abord)

- **Identifiant Android** : `com.ticketsur.fasosoft` (décidé le 2026-11-18, définitif à la première publication Google Play).
- **Versions épinglées** : Flutter 3.50.0 · Dart 3.14.0 · `material_ui` 1.11 (Material est sorti du cœur de Flutter depuis 3.47 : on importe `package:material_ui/material_ui.dart`, jamais `package:flutter/material.dart`) · Riverpod 3.5 · GoRouter 18.1 · very_good_analysis 11.
- **Polices** : Nunito (titres) et Inter (interface), variables, embarquées sous licence SIL OFL (`assets/fonts/`).

## Structure

```text
lib/
  app/                 racine, routes et redirections de session, AppConfig
  design_system/       couleurs, espacements, thèmes clair/sombre, couleurs de verdict
  features/
    scanner/
      domain/          TicketQrPayload (format TS1), ScanVerdict (contrat validate_scan v1)
      presentation/    écrans de verdict S23–S26, écran « Vérification… », galerie de revue
    auth/              connexion S03, mot de passe oublié S04 (domaine, Supabase, écrans)
    home/              accueil connecté provisoire, déconnexion
    welcome/           accueil S02
  l10n/                ARB français + code généré (lib/l10n/gen)
test/                  contrastes WCAG, domaine, écrans, démarrage
```

## Commandes

```bash
flutter pub get
flutter run --dart-define-from-file=config/staging.json   # projet Supabase de staging
flutter analyze --fatal-infos
dart format --set-exit-if-changed lib test
flutter test
```

## Android

- `android/` généré par `flutter create` (Flutter 3.50.0, Gradle 9.5, Android Gradle Plugin 9.3.1), puis ajusté : `com.ticketsur.fasosoft`, `minSdk 24`, `targetSdk 36`, permission Internet, lien profond `com.ticketsur.fasosoft://reset-password`, sauvegarde cloud désactivée (la session ne quitte pas le téléphone).
- Icône adaptative et icône thématique (monochrome) dérivées de `assets/branding/Tikeo_Icone.png` (logo Tikéo, ADR 0011) ; fond bleu « Nuit » `#022445` ; ticket et repère réduits pour tenir dans la zone sûre des masques circulaires.
- APK de pilote : workflow `android-build`, artefact téléchargeable dans l'onglet *Actions* : une APK `arm64-v8a` (la plupart des téléphones) et une `armeabi-v7a` (téléphones 32 bits anciens), avec `SHA256SUMS.txt`. Signée avec la clé de débogage tant qu'aucun keystore de publication n'est fourni par les secrets GitHub (`TICKETSUR_KEYSTORE_*`).

## À venir

- Écran de nouveau mot de passe ouvert par le lien de l'e-mail (lien profond `com.ticketsur.fasosoft://reset-password`, nécessite `android/`).

`assets/branding/` contient les actifs officiels : ne pas les redessiner.
