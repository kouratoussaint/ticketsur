-- =============================================================================
-- TicketSûr — Suppression des comptes jetables créés par scripts/e2e-auth-api.sh
-- (adresses e2e-…@example.com) et de leurs traces de test. Idempotent.
-- =============================================================================
\set ON_ERROR_STOP 1
begin;
create temp table e2e_accounts on commit drop as
  select id from auth.users where email like 'e2e-%@example.com';
delete from public.scan_attempts where actor_id in (select id from e2e_accounts);
delete from public.scan_requests where actor_id in (select id from e2e_accounts);
delete from auth.users where id in (select id from e2e_accounts); -- profils supprimés en cascade
\pset tuples_only on
select 'OK    comptes jetables supprimés : ' || count(*) from e2e_accounts;
commit;
