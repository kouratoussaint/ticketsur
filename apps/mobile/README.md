# Application mobile TicketSûr (Flutter, Android d'abord)

- **Identifiant Android** : `com.ticketsur.fasosoft` (décidé le 2026-11-18, définitif à la première publication Google Play).
- **Versions épinglées** : Flutter 3.50.0 · Dart 3.14.0 · `material_ui` 1.11 (Material est sorti du cœur de Flutter depuis 3.47 : on importe `package:material_ui/material_ui.dart`, jamais `package:flutter/material.dart`) · Riverpod 3.5 · GoRouter 18.1 · very_good_analysis 11.
- **Polices** : Manrope (titres) et Inter (interface), variables, embarquées sous licence SIL OFL (`assets/fonts/`).

## Structure

```text
lib/
  app/                 racine MaterialApp.router, routes
  design_system/       couleurs, espacements, thèmes clair/sombre, couleurs de verdict
  features/
    scanner/
      domain/          TicketQrPayload (format TS1), ScanVerdict (contrat validate_scan v1)
      presentation/    écrans de verdict S23–S26, écran « Vérification… », galerie de revue
    welcome/           accueil S02
  l10n/                ARB français + code généré (lib/l10n/gen)
test/                  contrastes WCAG, domaine, écrans, démarrage
```

## Commandes

```bash
flutter pub get
flutter analyze --fatal-infos
dart format --set-exit-if-changed lib test
flutter test
```

## À venir dans ce lot (Phase 1)

- Dossier `android/` (génération via l'outil Very Good CLI), `minSdk 24`, `targetSdk 36`, icône adaptative et splash depuis `assets/branding/`.
- Connexion Supabase (S03, S04) dès que le projet staging existe.

`assets/branding/` contient les actifs officiels : ne pas les redessiner.
