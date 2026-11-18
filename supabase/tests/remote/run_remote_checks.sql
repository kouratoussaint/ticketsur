-- =============================================================================
-- TicketSûr — Contrôles « connectés » sur un projet Supabase déployé
-- =============================================================================
-- Rapport en lecture seule : migrations, RLS, droits, secrets Vault (NOMS
--    seulement, jamais les valeurs), fonctions security definer.
-- Les tests d'acceptation sont dans remote_acceptance.sql (exécutés seulement
-- quand toutes les migrations du dépôt sont déployées).
-- Exécuté par .github/workflows/staging-tests.yml (mot de passe dans GitHub),
-- suivi de scripts/e2e-auth-api.sh (vrai compte, vrai jeton) et du nettoyage.
-- =============================================================================
\set ON_ERROR_STOP 1
\pset pager off

\echo '== Migrations appliquées'
select version, name from supabase_migrations.schema_migrations order by version;

\echo '== Tables exposées sans RLS (attendu : aucune)'
select c.relname as table_sans_rls
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;

\echo '== Droits accordés au rôle anon sur public (attendu : aucun)'
select table_name, privilege_type
from information_schema.role_table_grants
where grantee = 'anon' and table_schema = 'public';

\echo '== Fonctions security definer sans search_path fixé (attendu : aucune)'
select n.nspname || '.' || p.proname as fonction
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public', 'private') and p.prosecdef
  and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%');

\echo '== Secrets Vault TicketSûr (noms et longueurs, jamais les valeurs)'
select name, length(decrypted_secret) as longueur
from vault.decrypted_secrets where name like 'ticketsur_%' order by name;

do $$
begin
  if exists (select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
             where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity) then
    raise exception 'ÉCHEC  table publique sans RLS';
  end if;
  if exists (select 1 from information_schema.role_table_grants
             where grantee = 'anon' and table_schema = 'public') then
    raise exception 'ÉCHEC  droits accordés à anon';
  end if;
  if (select count(*) from vault.decrypted_secrets
      where name in ('ticketsur_qr_hmac_key', 'ticketsur_qr_encryption_key')
        and length(decrypted_secret) >= 32) <> 2 then
    raise exception 'ÉCHEC  clés Vault TicketSûr absentes ou trop courtes';
  end if;
  raise notice 'OK    rapport de configuration conforme';
end $$;
