<p align="center">
  <img src="apps/mobile/assets/branding/TicketSur_Logo_Officiel.png" alt="TicketSûr — Votre événement en un clic" width="420">
</p>

# TicketSûr

**Votre événement en un clic.** Application Android de billetterie événementielle et de contrôle d'accès par QR code à usage unique, multi-organisations, conçue pour démarrer au Burkina Faso.

> **Invariant produit.** Pour tout billet à entrée unique, le serveur enregistre **au plus une** validation acceptée, même si plusieurs contrôleurs scannent le même QR au même instant. Le téléphone n'accorde jamais une entrée seul.
>
> **Limite assumée.** Un QR photographié reste utilisable par la première personne qui le présente : le système garantit qu'une seule copie passe, pas que ce soit la bonne.

## État du projet

| Phase | Contenu | État |
| --- | --- | --- |
| 0 — Cadrage | ADR, architecture, backlog, prototype du moteur de scan | En revue (PR #1) |
| 1 — Fondations | App Flutter, design system, CI complète, projets Supabase | À faire |
| 2 → 6 | Données, billets, scan, UX terrain, livraison | Voir `docs/product/backlog.md` |

## Architecture en bref

- **Mobile** : Flutter / Dart, Android d'abord (`targetSdk 36`), Material 3 personnalisé, Riverpod, GoRouter, `mobile_scanner`.
- **Backend** : Supabase (Auth, PostgreSQL, Storage). Le verdict d'un scan est rendu par une **fonction PostgreSQL transactionnelle** (`public.validate_scan`) appelée en RPC — voir [ADR 0002](docs/decisions/0002-validation-par-rpc-postgresql.md).
- **QR** : jeton opaque de 256 bits `TS1.<base64url>`, aucune donnée personnelle ; la base ne conserve qu'un HMAC et une copie chiffrée — voir [ADR 0003](docs/decisions/0003-secrets-qr-hmac-et-copie-chiffree.md).
- **En ligne obligatoire** pour accepter une entrée au MVP — voir [ADR 0004](docs/decisions/0004-pas-de-validation-hors-ligne-au-mvp.md).

## Structure du dépôt

```text
ticketsur/
  .github/                 workflows CI, modèles d'issues et de PR, CODEOWNERS
  apps/mobile/             application Flutter (initialisée en Phase 1)
    assets/branding/       logo et icône officiels (ne pas redessiner)
  supabase/
    migrations/            schéma, RLS, fonctions — source de vérité de la base
    tests/shim/            émulation minimale de Supabase pour PostgreSQL nu (CI)
    tests/sql/             données de test et tests d'acceptation
    tests/concurrency/     preuve de l'invariant sous concurrence réelle
  docs/                    produit, architecture, décisions (ADR), sécurité
  scripts/                 outils de développement
```

## Lancer les tests de la base

Prérequis : PostgreSQL 15 ou plus, accessible par un superutilisateur.

```bash
export PGHOST=localhost PGPORT=5432 PGUSER=postgres PGPASSWORD=postgres
bash scripts/db-test.sh
```

Le script recrée une base jetable `ticketsur_test`, applique les migrations, puis exécute les tests d'acceptation, les tests de concurrence (2 et 50 scans simultanés, rejeux idempotents) et un test de volume de 10 000 billets. Il s'arrête au premier échec.

## APK de pilote

Dernière version (staging, signée avec la clé stable, s'installe par-dessus la précédente) :

- téléphones récents : https://github.com/kouratoussaint/ticketsur/releases/latest/download/TicketSur-staging-arm64-v8a.apk
- anciens appareils 32 bits : https://github.com/kouratoussaint/ticketsur/releases/latest/download/TicketSur-staging-armeabi-v7a.apk

Publiée automatiquement par `android-build` à chaque fusion sur `main` (GitHub Releases, versions `pilote-<build>`, les 15 dernières sont gardées).

## Déploiement

Le projet Supabase de **staging** reçoit les migrations par GitHub Actions (`deploy-staging`) à chaque fusion sur `main`. Mise en place et vérifications : [docs/operations/deploiement-supabase.md](docs/operations/deploiement-supabase.md).

## Sécurité

Ce dépôt est **public** : aucun secret n'y entre jamais, ni clé `service_role`, ni clé de signature Android, ni secret Vault. Voir [SECURITY.md](SECURITY.md) et [`.env.example`](.env.example).

## Documentation

- Cahier des charges : [docs/product/cahier-des-charges.md](docs/product/cahier-des-charges.md)
- Décisions d'architecture : [docs/decisions/](docs/decisions/)
- Moteur de scan : [docs/architecture/moteur-de-scan.md](docs/architecture/moteur-de-scan.md)
- Contribution : [CONTRIBUTING.md](CONTRIBUTING.md)
