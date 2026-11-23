-- =============================================================================
-- Tikéo — Tests : vues de la fiche publique, abonnés d'une structure (migration 6100)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6100-0000-0000-000000000001', 'proprio-audience@test.local', now()),
  ('aaaaaaaa-6100-0000-0000-000000000002', 'gestion-audience@test.local', now()),
  ('aaaaaaaa-6100-0000-0000-000000000003', 'controle-audience@test.local', now()),
  ('aaaaaaaa-6100-0000-0000-000000000004', 'fan1-audience@test.local', now()),
  ('aaaaaaaa-6100-0000-0000-000000000005', 'fan2-audience@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-6100-0000-0000-000000000001');
select (public.create_organization('Audience Prod Uq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Uq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select (public.create_event(:'org', 'Brouillon Uq', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as ev_draft \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-6100-0000-0000-000000000002', 'manager'),
  (:'org', 'aaaaaaaa-6100-0000-0000-000000000003', 'controller');

-- Vues : visiteurs et comptes (un visiteur par jour : migration 6200) -----------
select test.login(null);
set role anon;
select public.record_event_view(:'ev');
select public.record_event_view(:'ev');
select public.record_event_view(:'ev_draft');
select public.record_event_view('00000000-0000-0000-0000-000000000000');
set role authenticated;
select test.login('aaaaaaaa-6100-0000-0000-000000000004');
select public.record_event_view(:'ev');
reset role;
-- Une vue d'il y a 10 jours : comptée au total, pas sur 7 jours.
insert into public.event_page_views (event_id, day, views)
values (:'ev', (now() at time zone 'UTC')::date - 10, 5);

set role authenticated;
select test.login('aaaaaaaa-6100-0000-0000-000000000002');
select test.check('Vues : total, 7 jours, 30 jours, aujourd''hui',
  (select (j->>'total') || '|' || (j->>'last_7') || '|' || jsonb_array_length(j->'days')
          || '|' || (j->'days'->29->>'count') || '|' || (j->'days'->19->>'count')
     from public.event_page_views(:'ev') j),
  '7|2|30|2|5');
select test.check('Brouillon : aucune vue comptée',
  public.event_page_views(:'ev_draft')->>'total', '0');
select test.login('aaaaaaaa-6100-0000-0000-000000000003');
select test.expect_error('Contrôleur : vues refusées',
  format('select public.event_page_views(%L)', :'ev'), 'event_not_found');
reset role;
select test.check('Vues fermées à l''API et aux visiteurs',
  has_table_privilege('anon', 'public.event_page_views', 'select')::text || '|'
  || has_function_privilege('anon', 'public.event_page_views(uuid)', 'execute')::text,
  'false|false');

-- Abonnés --------------------------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-6100-0000-0000-000000000004');
select public.follow_organization(:'org', true) \gset ignored_
select test.login('aaaaaaaa-6100-0000-0000-000000000005');
select public.follow_organization(:'org', true) \gset ignored_
reset role;
update public.organization_followers set created_at = now() - interval '40 days'
 where organization_id = :'org' and user_id = 'aaaaaaaa-6100-0000-0000-000000000005';
set role authenticated;
select test.login('aaaaaaaa-6100-0000-0000-000000000001');
select test.check('Abonnés : nombre, arrivées sur 30 jours, aujourd''hui',
  (select (j->>'followers') || '|' || (j->>'new_30d') || '|' || jsonb_array_length(j->'days')
          || '|' || (j->'days'->29->>'count')
     from public.organization_followers_stats(:'org') j),
  '2|1|30|1');
select test.login('aaaaaaaa-6100-0000-0000-000000000003');
select test.expect_error('Contrôleur : abonnés refusés',
  format('select public.organization_followers_stats(%L)', :'org'), 'organization_not_found');
reset role;
