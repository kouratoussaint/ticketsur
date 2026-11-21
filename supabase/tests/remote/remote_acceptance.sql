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
\ir ../sql/35_event_content.sql
\ir ../sql/36_profile_org.sql
\ir ../sql/40_categories_checkpoints.sql
\ir ../sql/50_team.sql
\ir ../sql/60_tickets.sql
\ir ../sql/70_controller.sql
\ir ../sql/80_dashboard.sql
\ir ../sql/90_named_tickets.sql
\ir ../sql/95_deliveries.sql
\ir ../sql/96_report.sql
\ir ../sql/97_invitations.sql
\ir ../sql/98_public_catalog.sql
\ir ../sql/99_console.sql
\ir ../sql/99_console_accounts.sql
\ir ../sql/99_support.sql
\ir ../sql/99_legal.sql
\ir ../sql/99_bulk_duplicate.sql
\ir ../sql/99_wallet.sql
\ir ../sql/99_push.sql
\ir ../sql/99_door.sql
\ir ../sql/99_templates.sql
\ir ../sql/99_entries.sql
\ir ../sql/99_reminders.sql
\ir ../sql/99_billing.sql
\ir ../sql/99_billing_console.sql
\ir ../sql/99_billing_promoter.sql
\ir ../sql/99_featured.sql
\ir ../sql/99_invitation_reveal.sql
\ir ../sql/99_assign_organization.sql
\ir ../sql/99_devices.sql
\ir ../sql/99_promoter_search.sql
\ir ../sql/99_safeupdate.sql
rollback;

\echo '== Aucune donnée de test résiduelle'
\pset tuples_only on
select case when exists (select 1 from public.organizations where slug in ('org-a', 'org-b'))
            then 'ÉCHEC  données de test résiduelles' else 'OK    base propre après les tests' end;
