# ADR 0005 — Monorepo et tests de base exécutables sur PostgreSQL nu

- **Statut** : proposé (Phase 0)
- **Date** : 2026-11-18

## Décision

- Un seul dépôt : `apps/mobile` (Flutter), `supabase/` (migrations, tests), `docs/`, `.github/`.
- Les tests de la base tournent sur **n'importe quel PostgreSQL 15+** grâce à un shim minimal (`supabase/tests/shim/`) qui fournit les rôles `anon`/`authenticated`/`service_role`, `auth.uid()`, le schéma `extensions` et une vue `vault.decrypted_secrets`.
- Les tests de concurrence ouvrent de vraies connexions parallèles, libérées ensemble par un verrou consultatif.

## Pourquoi

- La CI reste rapide et indépendante de la pile Docker de Supabase CLI.
- Les mêmes migrations s'appliquent ensuite telles quelles sur Supabase (les objets du shim y existent déjà).

## Suite

En Phase 1, un second job exécutera les mêmes tests contre `supabase start` (pile locale complète) pour détecter tout écart avec la plateforme réelle.
