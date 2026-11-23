-- =============================================================================
-- Tikéo — Tests : promoteur prévenu des changements d'abonnement (migration 6300)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6300-0000-0000-000000000001', 'promoteur-notif-pack@test.local', now()),
  ('aaaaaaaa-6300-0000-0000-000000000002', 'admin-notif-pack@test.local', now());
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-6300-0000-0000-000000000002';

set role authenticated;
select test.login('aaaaaaaa-6300-0000-0000-000000000002');
select public.admin_save_pack(null, $j${
  "name": "Notif A Sq", "system": "flat", "monthly_price": 4000,
  "durations": {"month": 4000},
  "options": [{"key": "members_per_structure", "included": 1, "addon_price": 500}]
  }$j$::jsonb) as pack_a \gset
select public.admin_save_pack(null, $j${
  "name": "Notif B Sq", "system": "flat", "monthly_price": 2000,
  "durations": {"month": 2000},
  "options": [{"key": "members_per_structure", "included": 2, "addon_price": 400}]
  }$j$::jsonb) as pack_b \gset
select public.admin_grant_subscription('aaaaaaaa-6300-0000-0000-000000000001', :'pack_a', 'month',
                                       'Offert Sq', '{}') as sub \gset
reset role;
select max(id) as before from public.push_outbox \gset
set role authenticated;
select test.login('aaaaaaaa-6300-0000-0000-000000000002');
select public.admin_change_subscription_pack(:'sub', :'pack_b', 'Passage B') \gset ignored_
select public.admin_change_subscription_pack(:'sub', :'pack_b', 'Même pack') \gset ignored_
select public.admin_extend_subscription(:'sub', '2031-03-15 12:00+00', 'Geste') \gset ignored_
select public.admin_set_subscription_addons(:'sub', '{"members_per_structure": 2}', 'Renfort') \gset ignored_
reset role;

select test.check('Trois messages au promoteur (rien si le pack ne change pas)',
  (select string_agg(title || ' → ' || body || ' [' || route || ']', ' | ' order by id)
     from public.push_outbox
    where id > coalesce(:'before'::bigint, 0)
      and user_id = 'aaaaaaaa-6300-0000-0000-000000000001'),
  'Votre pack a changé → Votre pack est maintenant Notif B Sq (au lieu de Notif A Sq). Vos dates ne changent pas. [/facturation]'
  || ' | Date de fin de votre pack modifiée → Votre pack Notif B Sq se termine maintenant le 15/03/2031. [/facturation]'
  || ' | Suppléments modifiés → Les suppléments de votre pack Notif B Sq ont été mis à jour. [/facturation]');
select test.check('Aucun message à l''administrateur',
  (select count(*)::text from public.push_outbox
    where id > coalesce(:'before'::bigint, 0)
      and user_id = 'aaaaaaaa-6300-0000-0000-000000000002'), '0');
select test.check('Permission « facturation » toujours posée',
  (select string_agg(p.proname || '=' || coalesce(array_to_string(p.proconfig, ','), '∅'), ' ' order by p.proname)
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('admin_change_subscription_pack', 'admin_extend_subscription',
                        'admin_set_subscription_addons')),
  'admin_change_subscription_pack=search_path="",application_name=tikeo.perm:billing'
  || ' admin_extend_subscription=search_path="",application_name=tikeo.perm:billing'
  || ' admin_set_subscription_addons=search_path="",application_name=tikeo.perm:billing');
