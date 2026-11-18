# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versionnement sémantique à partir de la première APK pilote.

## [Non publié]

### Ajouté
- Phase 0 : ADR 0001 à 0005, documentation du moteur de scan, backlog.
- Migrations `0100` (schéma multi-organisations, RLS de lecture) et `0200` (émission, révocation, validation atomique des scans avec idempotence).
- Tests base de données : 47 assertions (acceptation, concurrence 2 et 50 scans, rejeux idempotents simultanés, 10 000 billets).
- Workflows GitHub Actions `db-tests` et `security`.
- Actifs de marque officiels (logo, icône Android).
