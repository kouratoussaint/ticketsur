-- =============================================================================
-- Tikéo — Tests : maintenance, inscriptions, exports (migration 5300)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
-- État connu, quel que soit le réglage du staging (transaction annulée).
update private.console_settings s
   set value = case s.key when 'signups_open' then 'true'::jsonb
                          when 'maintenance_message' then '""'::jsonb
                          else 'false'::jsonb end
 where s.key in ('maintenance', 'maintenance_message', 'maintenance_writes', 'signups_open');
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5300-0000-0000-000000000001', 'super-maint@test.local', now()),
  ('aaaaaaaa-5300-0000-0000-000000000002', 'finance-maint@test.local', now()),
  ('aaaaaaaa-5300-0000-0000-000000000003', 'awa-maint@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-5300-0000-0000-000000000001', 'aaaaaaaa-5300-0000-0000-000000000002');
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-5300-0000-0000-000000000002', 'finance');

set role authenticated;
select test.login('aaaaaaaa-5300-0000-0000-000000000003');
select (public.create_organization('Studio Maint Xq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Maint Xq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
create temp table issued_5300 as select * from public.issue_tickets(:'ev', :'cat', 2);
select (public.create_invitation(:'org', 'controller', 7, 5))->>'code' as code \gset
select min(t.id::text) as ticket from public.tickets t where t.event_id = :'ev' \gset
select (public.create_event(:'org', 'Second Maint Xq', now() + interval '8 days',
                            now() + interval '8 days 4 hours')).id as ev2 \gset

-- État public -------------------------------------------------------------------------
reset role;
select test.login(null);
set role anon;
select public.platform_status() as st \gset
reset role;
select test.check('Visiteur : pas de maintenance, inscriptions ouvertes',
  (select (s->>'maintenance') || ':' || (s->>'signups_open') || ':' || coalesce(s->>'message', '-')
     from (select :'st'::jsonb s) x), 'false:true:-');
set role authenticated;

-- Réglage (permission settings) -------------------------------------------------------
select test.login('aaaaaaaa-5300-0000-0000-000000000002');
select test.expect_error('Finance : réglage refusé',
  $q$select public.admin_save_platform_status(true, 'Mise à jour', true, true)$q$,
  'admin_role_forbidden');
select test.login('aaaaaaaa-5300-0000-0000-000000000001');
select test.expect_error('Message trop long',
  $q$select public.admin_save_platform_status(true, repeat('x', 301), true, true)$q$,
  'maintenance_message_invalid');
select test.check('Maintenance avec modifications bloquées',
  (select (s->>'maintenance') || ':' || (s->>'writes_blocked') || ':' || (s->>'message')
     from public.admin_save_platform_status(true, '  Mise à jour du serveur  ', true, true) s),
  'true:true:Mise à jour du serveur');

-- Promoteur pendant la maintenance ----------------------------------------------------
select test.login('aaaaaaaa-5300-0000-0000-000000000003');
select test.expect_error('Maintenance : créer un événement refusé',
  $q$select public.create_event('$q$ || :'org' || $q$', 'Pendant Maint Xq', now() + interval '6 days', now() + interval '6 days 2 hours')$q$,
  'maintenance');
select test.expect_error('Maintenance : émettre refusé',
  $q$select * from public.issue_tickets('$q$ || :'ev' || $q$', '$q$ || :'cat' || $q$', 1)$q$,
  'maintenance');
select test.expect_error('Maintenance : annuler un ticket refusé',
  $q$select public.revoke_ticket('$q$ || :'ticket' || $q$', 'Motif')$q$, 'maintenance');
select test.check('Maintenance : démarrer le contrôle reste possible',
  (public.set_event_status(:'ev', 'in_progress')).status::text, 'in_progress');

-- Administrateur pendant la maintenance -----------------------------------------------
select test.login('aaaaaaaa-5300-0000-0000-000000000001');
select test.check('Maintenance : l''administrateur modifie',
  ((select (r->'fields')::text from public.admin_update_event(:'ev2', 'Second Maint Xq bis',
     now() + interval '8 days', now() + interval '8 days 4 hours',
     'Africa/Ouagadougou', null, null, null, null, null, null, null, 'Correction') r) like '%title%')::text,
  'true');
select public.admin_save_platform_status(false, null, true, true) \gset ignored_
select test.login('aaaaaaaa-5300-0000-0000-000000000003');
select test.check('Fin de maintenance : créer un événement',
  ((public.create_event(:'org', 'Après Maint Xq', now() + interval '6 days',
                        now() + interval '6 days 2 hours')).id is not null)::text, 'true');

-- Inscriptions fermées ----------------------------------------------------------------
select test.login('aaaaaaaa-5300-0000-0000-000000000001');
select test.check('Inscriptions fermées',
  (public.admin_save_platform_status(false, null, false, false)->>'signups_open'), 'false');
reset role;
select test.expect_error('Inscription sans code refusée',
  $q$insert into auth.users (id, email, created_at) values ('aaaaaaaa-5300-0000-0000-000000000004', 'sans-code-maint@test.local', now())$q$,
  'signups_closed');
select test.expect_error('Inscription avec un mauvais code refusée',
  $q$insert into auth.users (id, email, created_at, raw_user_meta_data) values ('aaaaaaaa-5300-0000-0000-000000000004', 'mauvais-code-maint@test.local', now(), '{"invitation_code": "AAAA-BBBB"}')$q$,
  'signups_closed');
insert into auth.users (id, email, created_at, raw_user_meta_data) values
  ('aaaaaaaa-5300-0000-0000-000000000005', 'code-maint@test.local', now(),
   jsonb_build_object('display_name', 'Issa Code', 'invitation_code', :'code'));
select test.check('Inscription avec un code valable ; le code n''est pas gardé',
  (select p.display_name || ':' || (u.raw_user_meta_data ? 'invitation_code')
     from public.profiles p join auth.users u on u.id = p.id
    where p.id = 'aaaaaaaa-5300-0000-0000-000000000005'), 'Issa Code:false');
insert into auth.users (id, email, created_at, raw_app_meta_data) values
  ('aaaaaaaa-5300-0000-0000-000000000006', 'console-maint@test.local', now(),
   '{"provider": "email", "tikeo_admin_created": true}');
select test.check('Compte créé par la console accepté',
  (select count(*)::text from public.profiles p
    where p.id = 'aaaaaaaa-5300-0000-0000-000000000006'), '1');
update private.console_settings s set value = 'true'::jsonb where s.key = 'signups_open';
set role authenticated;

-- Exports -----------------------------------------------------------------------------
select test.login('aaaaaaaa-5300-0000-0000-000000000002');
select test.expect_error('Finance : export des comptes refusé',
  $q$select public.admin_export('accounts')$q$, 'admin_role_forbidden');
select test.check('Finance : export des factures (12 colonnes)',
  jsonb_array_length(public.admin_export('invoices')->'columns')::text, '12');
select test.expect_error('Export inconnu',
  $q$select public.admin_export('tickets')$q$, 'export_kind_invalid');
select test.login('aaaaaaaa-5300-0000-0000-000000000001');
select public.admin_export('accounts') as accounts \gset
select test.check('Export des comptes : la promotrice et son e-mail',
  (select (r->>2) from jsonb_array_elements((:'accounts'::jsonb)->'rows') r
    where r->>0 = 'aaaaaaaa-5300-0000-0000-000000000003'), 'awa-maint@test.local');
select test.check('Export des événements : tickets et entrés',
  (select (r->>8) || ':' || (r->>9) from jsonb_array_elements(public.admin_export('events')->'rows') r
    where r->>0 = :'ev'), '2:0');
select test.check('Export des structures et du journal',
  ((select count(*) from jsonb_array_elements(public.admin_export('organizations')->'rows') r
     where r->>0 = :'org') = 1
   and jsonb_array_length(public.admin_export('journal')->'rows') > 0)::text, 'true');
select test.check('Journal : exports avec type et nombre de lignes seulement',
  (select string_agg(distinct l.details->>'export', ',' order by l.details->>'export')
     from public.admin_audit_logs('admin.export', 50, 0,
       p_actor_id => 'aaaaaaaa-5300-0000-0000-000000000001') l),
  'accounts,events,journal,organizations');
select test.check('Journal : réglage de la plateforme sans le message',
  (select bool_and(not (l.details::text like '%Mise à jour%'))::text
     from public.admin_audit_logs('admin.platform_status', 50, 0) l), 'true');
reset role;
