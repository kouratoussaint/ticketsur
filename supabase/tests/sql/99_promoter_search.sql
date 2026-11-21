-- =============================================================================
-- Tikéo — Tests : recherche globale du promoteur (migration 4400)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4400-0000-0000-000000000001', 'proprio-recherche@test.local'),
  ('aaaaaaaa-4400-0000-0000-000000000002', 'gestion-recherche@test.local'),
  ('aaaaaaaa-4400-0000-0000-000000000003', 'controle-recherche@test.local'),
  ('aaaaaaaa-4400-0000-0000-000000000004', 'autre-recherche@test.local');

set role authenticated;
select test.login('aaaaaaaa-4400-0000-0000-000000000001');
select (public.create_organization('Studio Recherche Wqz')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Nuit du Djembé Wqz', now() + interval '3 days',
                            now() + interval '3 days 5 hours')).id as ev1 \gset
select (public.create_event(:'org', 'Forum Wqz', now() + interval '10 days',
                            now() + interval '10 days 8 hours')).id as ev2 \gset
select (public.create_ticket_category(:'ev1', 'Standard')).id as cat1 \gset
select (public.create_ticket_category(:'ev2', 'VIP')).id as cat2 \gset
select test.complete_event(:'ev1') \gset ignored_
select public.set_event_status(:'ev1', 'published') \gset ignored_
select test.complete_event(:'ev2') \gset ignored_
select public.set_event_status(:'ev2', 'published') \gset ignored_
create temp table rows1 as select * from public.issue_named_tickets(:'ev1', jsonb_build_array(
  jsonb_build_object('category_id', :'cat1', 'name', 'Aïcha Ouédraogo', 'phone', '+22670112233'),
  jsonb_build_object('category_id', :'cat1', 'name', 'Issa Kaboré')));
create temp table rows2 as select * from public.issue_named_tickets(:'ev2', jsonb_build_array(
  jsonb_build_object('category_id', :'cat2', 'name', 'Awa Ouedraogo')));
select public_reference as ref1 from rows1 where line = 2 \gset

-- Autre structure : jamais dans les résultats.
select test.login('aaaaaaaa-4400-0000-0000-000000000004');
select (public.create_organization('Ailleurs Wqz')::jsonb)->>'id' as org_other \gset
select (public.create_event(:'org_other', 'Nuit Wqz ailleurs', now() + interval '3 days',
                            now() + interval '3 days 5 hours')).id as ev3 \gset
select (public.create_ticket_category(:'ev3', 'Standard')).id as cat3 \gset
select test.complete_event(:'ev3') \gset ignored_
select public.set_event_status(:'ev3', 'published') \gset ignored_
select count(*) from public.issue_named_tickets(:'ev3', jsonb_build_array(
  jsonb_build_object('category_id', :'cat3', 'name', 'Aïcha Ouédraogo'))) \gset ignored_

reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-4400-0000-0000-000000000002', 'manager'),
  (:'org', 'aaaaaaaa-4400-0000-0000-000000000003', 'controller');
set role authenticated;

select test.login('aaaaaaaa-4400-0000-0000-000000000001');
select test.check('Nom sans accents : tickets des deux événements, pas d''une autre structure',
  (select string_agg(t->>'holder_name' || '@' || (t->>'event_title'), ',' order by t->>'event_title')
     from jsonb_array_elements((public.promoter_search(:'org', 'ouedraogo'))->'tickets') t),
  'Awa Ouedraogo@Forum Wqz,Aïcha Ouédraogo@Nuit du Djembé Wqz');
select test.check('Téléphone par ses chiffres (4 au moins)',
  (select string_agg(t->>'holder_name', ',')
     from jsonb_array_elements((public.promoter_search(:'org', '70 11'))->'tickets') t),
  'Aïcha Ouédraogo');
select test.check('Référence exacte en premier, avec l''événement et la catégorie',
  (select (t->>'public_reference') || ':' || (t->>'category') || ':' || (t->>'status')
     from jsonb_array_elements((public.promoter_search(:'org', :'ref1'))->'tickets') t limit 1),
  :'ref1' || ':Standard:issued');
select test.check('Événements : titre sans accents, ceux de la structure seulement',
  (select string_agg(e->>'title', ',')
     from jsonb_array_elements((public.promoter_search(:'org', 'djembe'))->'events') e),
  'Nuit du Djembé Wqz');
select test.check('Rien ne correspond : listes vides',
  (public.promoter_search(:'org', 'zzzzqq'))::text, '{"events": [], "tickets": []}');

select test.login('aaaaaaaa-4400-0000-0000-000000000002');
select test.check('Gestionnaire : même recherche',
  jsonb_array_length((public.promoter_search(:'org', 'wqz'))->'events')::text, '2');

select test.login('aaaaaaaa-4400-0000-0000-000000000003');
select test.expect_error('Contrôleur : refusé',
  format($q$select public.promoter_search(%L, 'awa')$q$, :'org'), 'forbidden');
select test.login('aaaaaaaa-4400-0000-0000-000000000004');
select test.expect_error('Autre structure : refusé',
  format($q$select public.promoter_search(%L, 'awa')$q$, :'org'), 'forbidden');
select test.login('aaaaaaaa-4400-0000-0000-000000000001');
select test.expect_error('Une seule lettre : refusé',
  format($q$select public.promoter_search(%L, ' a ')$q$, :'org'), 'search_query_invalid');
reset role;
