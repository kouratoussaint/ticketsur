-- =============================================================================
-- Tikéo — Tests : UPDATE et DELETE toujours avec WHERE (migration 3900)
-- Sur Supabase, l'extension safeupdate refuse un UPDATE ou un DELETE sans
-- WHERE dans les requêtes de l'API, y compris dans nos fonctions. Elle n'existe
-- pas en local : on vérifie le code des fonctions de public et private.
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
select test.check('Fonctions : aucun UPDATE ni DELETE sans WHERE',
  coalesce((
    select string_agg(distinct x.proname, ', ' order by x.proname)
      from (
        select p.proname, s.stmt
          from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         cross join lateral regexp_split_to_table(
                 regexp_replace(p.prosrc, '--[^\n]*', '', 'g'), ';') as s(stmt)
         where n.nspname in ('public', 'private') and p.prolang <> 13
      ) x
     where x.stmt ~* '\m(update|delete\s+from)\s+(public|private)\.\w+'
       and x.stmt !~* '\mwhere\M'), ''),
  '');

-- Le réglage s'enregistre (la fonction corrigée).
insert into auth.users (id, email) values
  ('aaaaaaaa-3900-0000-0000-000000000001', 'admin-reglages@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-3900-0000-0000-000000000001';
set role authenticated;
select test.login('aaaaaaaa-3900-0000-0000-000000000001');
select public.admin_save_billing_settings(
  '{"orange_money_number": "70 11 22 33", "beneficiary": "Tikéo test"}'::jsonb) \gset ignored_
reset role;
select test.check('Réglages de paiement : enregistrés',
  (select orange_money_number || ' / ' || beneficiary from public.billing_settings),
  '70 11 22 33 / Tikéo test');
set role authenticated;
