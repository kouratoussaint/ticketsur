# ADR 0001 — Stack : Flutter Android d'abord + Supabase

- **Statut** : proposé (Phase 0)
- **Date** : 2026-11-18

## Contexte

Le cahier des charges fixe une application Android maintenable, extensible vers iOS, avec un backend rapide à mettre en place et une base relationnelle capable de transactions strictes.

## Décision

- **Mobile** : Flutter stable courant (3.50 / Dart 3.14 en novembre 2026), version exacte épinglée à l'initialisation via `.fvmrc` ou équivalent et dans la CI.
- **Android** : `targetSdk 36` (exigé par Google Play pour toute nouvelle app depuis le 31/08/2026) ; `minSdk 24` visé, à confirmer avec la version de Flutter et des plugins retenus.
- **État / navigation** : Riverpod + GoRouter.
- **Scan** : `mobile_scanner` 7.x avec le modèle ML Kit **embarqué** (le mode non embarqué télécharge le modèle via Play Services au premier usage, risqué sur les appareils et réseaux visés).
- **Backend** : Supabase (Auth, PostgreSQL, Storage), client `supabase_flutter` 2.x.
- **Pas de backend NestJS** : il dupliquerait Auth, l'API et les autorisations déjà fournies.

## Conséquences

- Dépendance à un fournisseur : atténuée par des migrations SQL standard et une logique métier en PL/pgSQL portable.
- Material est en cours de découplage du cœur de Flutter : la dépendance exacte sera vérifiée à l'initialisation (Phase 1).
