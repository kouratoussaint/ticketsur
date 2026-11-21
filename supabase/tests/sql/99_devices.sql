-- =============================================================================
-- Tikéo — Tests : appareils connectés (migration 4300)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4300-0000-0000-000000000001', 'appareils-a@test.local'),
  ('aaaaaaaa-4300-0000-0000-000000000002', 'appareils-b@test.local');
insert into auth.sessions (id, user_id) values
  ('bbbbbbbb-4300-0000-0000-000000000001', 'aaaaaaaa-4300-0000-0000-000000000001'),
  ('bbbbbbbb-4300-0000-0000-000000000002', 'aaaaaaaa-4300-0000-0000-000000000001'),
  ('bbbbbbbb-4300-0000-0000-000000000003', 'aaaaaaaa-4300-0000-0000-000000000001'),
  ('bbbbbbbb-4300-0000-0000-000000000004', 'aaaaaaaa-4300-0000-0000-000000000002');

set role authenticated;
-- Téléphone 1 du compte A.
select set_config('request.jwt.claims', json_build_object('sub', 'aaaaaaaa-4300-0000-0000-000000000001',
  'role', 'authenticated', 'session_id', 'bbbbbbbb-4300-0000-0000-000000000001')::text, false) \gset ignored_
select test.check('Inscription : session du jeton',
  (public.register_device('Tecno Spark 10', 'android', 139))->>'session_id',
  'bbbbbbbb-4300-0000-0000-000000000001');
select public.register_device('Tecno Spark 10', 'android', 140) \gset ignored_

-- Téléphone 2 du compte A.
select set_config('request.jwt.claims', json_build_object('sub', 'aaaaaaaa-4300-0000-0000-000000000001',
  'role', 'authenticated', 'session_id', 'bbbbbbbb-4300-0000-0000-000000000002')::text, false) \gset ignored_
select public.register_device('Samsung A15', 'weird', null) \gset ignored_
select test.check('Liste : appareil en cours d''abord, session sans inscription comprise',
  (select string_agg(coalesce(label, '?') || ':' || platform_or || ':' || current::text, ',')
     from (select label, coalesce(platform, '-') as platform_or, current
             from public.my_devices()) x),
  'Samsung A15:other:true,Tecno Spark 10:android:false,?:-:false');
select test.check('Une seule ligne par session (mise à jour, pas de doublon)',
  (select app_build::text from public.my_devices()
    where session_id = 'bbbbbbbb-4300-0000-0000-000000000001'),
  '140');

select test.expect_error('Pas cet appareil : utiliser « Se déconnecter »',
  $q$select public.revoke_device('bbbbbbbb-4300-0000-0000-000000000002')$q$, 'device_current');
select test.expect_error('Appareil d''un autre compte : introuvable',
  $q$select public.revoke_device('bbbbbbbb-4300-0000-0000-000000000004')$q$, 'device_not_found');

select public.revoke_device('bbbbbbbb-4300-0000-0000-000000000001') \gset ignored_
select test.check('Appareil déconnecté : retiré de la liste',
  (select count(*)::text from public.my_devices()), '2');

-- Le téléphone 1 constate sa déconnexion à sa prochaine inscription.
select set_config('request.jwt.claims', json_build_object('sub', 'aaaaaaaa-4300-0000-0000-000000000001',
  'role', 'authenticated', 'session_id', 'bbbbbbbb-4300-0000-0000-000000000001')::text, false) \gset ignored_
select test.expect_error('Session supprimée : déconnexion signalée',
  $q$select public.register_device('Tecno Spark 10', 'android', 140)$q$, 'session_revoked');

-- Tous les autres appareils.
select set_config('request.jwt.claims', json_build_object('sub', 'aaaaaaaa-4300-0000-0000-000000000001',
  'role', 'authenticated', 'session_id', 'bbbbbbbb-4300-0000-0000-000000000002')::text, false) \gset ignored_
select test.check('Déconnecter les autres appareils : nombre', public.revoke_other_devices()::text, '1');
select test.check('Il ne reste que cet appareil',
  (select string_agg(label, ',') from public.my_devices()), 'Samsung A15');

-- L'autre compte n'est pas touché ; sans session dans le jeton : refusé.
reset role;
select test.check('Compte B intact',
  (select count(*)::text from auth.sessions where user_id = 'aaaaaaaa-4300-0000-0000-000000000002'), '1');
select test.check('Journal : sans détail personnel',
  (select string_agg(action || details::text, ',' order by action) from public.audit_logs
    where actor_id = 'aaaaaaaa-4300-0000-0000-000000000001' and action like 'account.device%'),
  'account.device_revoked{},account.devices_revoked{"count": 1}');
set role authenticated;
select test.login('aaaaaaaa-4300-0000-0000-000000000002');
select test.expect_error('Jeton sans session : refusé',
  $q$select public.register_device('X', 'android', 1)$q$, 'session_unknown');
select test.login(null);
select test.expect_error('Sans compte : refusé',
  $q$select * from public.my_devices()$q$, 'forbidden');
reset role;
