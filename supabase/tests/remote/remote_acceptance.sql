-- =============================================================================
-- TicketSûr — Tests d'acceptation connectés sur un projet Supabase déployé
-- =============================================================================
-- Comptes, organisations, événements et billets de test créés DANS UNE
-- TRANSACTION, scénarios joués sous le rôle « authenticated » (comme un vrai
-- appel API), puis ROLLBACK : la base n'en garde aucune trace.
-- Prérequis : toutes les migrations du dépôt sont déployées sur ce projet.
-- =============================================================================
\set ON_ERROR_STOP 1
\pset pager off

\echo '== Tests d''acceptation connectés (transaction annulée à la fin)'
begin;
\ir ../sql/00_fixtures.sql
\ir ../sql/10_scan_acceptance.sql
\ir ../sql/20_organizations.sql
\ir ../sql/30_events.sql
\ir ../sql/40_categories_checkpoints.sql
\ir ../sql/50_team.sql
rollback;

\echo '== Aucune donnée de test résiduelle'
\pset tuples_only on
select case when exists (select 1 from public.organizations where slug in ('org-a', 'org-b'))
            then 'ÉCHEC  données de test résiduelles' else 'OK    base propre après les tests' end;
