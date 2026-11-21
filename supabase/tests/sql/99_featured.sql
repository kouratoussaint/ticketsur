-- =============================================================================
-- Tikéo — Tests : événements « À la une » (migration 4000)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4000-0000-0000-000000000001', 'promoteur-une@test.local'),
  ('aaaaaaaa-4000-0000-0000-000000000003', 'admin-une@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-4000-0000-0000-000000000003';
-- Sur le staging : on part d'une liste vide (transaction annulée).
delete from public.featured_events where true;

set role authenticated;
select test.login('aaaaaaaa-4000-0000-0000-000000000001');
select (public.create_organization('Studio Une Qvx')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala Une Qvx', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as ev_a \gset
select (public.create_event(:'org', 'Concert Une Qvx', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev_b \gset
select (public.create_event(:'org', 'Atelier Une Qvx', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as ev_draft \gset
select test.complete_event(:'ev_a') \gset ignored_
select test.complete_event(:'ev_b') \gset ignored_
select public.set_event_status(:'ev_a', 'published') \gset ignored_
select public.set_event_status(:'ev_b', 'published') \gset ignored_

select test.check('Sans mise en avant : les 5 prochains événements publics',
  (select count(*)::text || ':' || (count(*) = (select count(*) from public.public_events(p_limit => 5)))::text
     from public.public_featured_events()),
  (select least(count(*), 5)::text || ':true' from public.public_events(p_limit => 50)));

select test.expect_error('Un promoteur ne gère pas la une',
  format($q$select public.admin_add_featured_event(%L)$q$, :'ev_a'), 'forbidden');

select test.login('aaaaaaaa-4000-0000-0000-000000000003');
select test.expect_error('Un brouillon ne peut pas être à la une',
  format($q$select public.admin_add_featured_event(%L)$q$, :'ev_draft'), 'featured_event_invalid');
select public.admin_add_featured_event(:'ev_b') as f_b \gset
select public.admin_add_featured_event(:'ev_a') as f_a \gset
select test.expect_error('Pas deux fois à la une',
  format($q$select public.admin_add_featured_event(%L)$q$, :'ev_a'), 'featured_exists');
select test.expect_error('Période invalide refusée',
  format($q$select public.admin_set_featured_period(%L, now(), now() - interval '1 day')$q$, :'f_a'),
  'featured_period_invalid');

select test.check('Ordre choisi par l''administrateur, fin par défaut = fin de l''événement',
  (select string_agg(title, ' > ' order by ord) from (
     select title, row_number() over () as ord from public.public_featured_events()) x)
   || ' | ' || (select ((e->>'ends_at')::timestamptz = (e->>'event_ends_at')::timestamptz)::text
                  from jsonb_array_elements(public.admin_featured_events()) e
                 where e->>'id' = :'f_a'),
  'Concert Une Qvx > Gala Une Qvx | true');

select public.admin_move_featured_event(:'f_a', -1) \gset ignored_
select test.check('Monter : Gala passe en tête',
  (select string_agg(title, ' > ' order by ord) from (
     select title, row_number() over () as ord from public.public_featured_events()) x),
  'Gala Une Qvx > Concert Une Qvx');
select public.admin_move_featured_event(:'f_a', -1) \gset ignored_
select test.check('Monter en tête : rien ne change',
  (select string_agg(e->>'title', ' > ' order by (e->>'position')::int)
     from jsonb_array_elements(public.admin_featured_events()) e),
  'Gala Une Qvx > Concert Une Qvx');

-- Période à venir : pas encore affichée.
select public.admin_set_featured_period(:'f_a', now() + interval '1 day', now() + interval '2 days')
  \gset ignored_
select test.check('Période à venir : pas encore à la une ; console la montre en attente',
  (select string_agg(title, ',') from public.public_featured_events())
   || ' | ' || (select string_agg((e->>'live'), ',' order by (e->>'position')::int)
                  from jsonb_array_elements(public.admin_featured_events()) e),
  'Concert Une Qvx | false,true');

select public.admin_remove_featured_event(:'f_b') \gset ignored_
select public.admin_remove_featured_event(:'f_a') \gset ignored_
reset role;
select test.check('Retirés : retour aux prochains événements ; journal sans donnée personnelle',
  (select count(*)::text from public.featured_events)
   || ' | ' || (select string_agg(distinct action, ',' order by action) from public.audit_logs
                 where action like 'admin.featured_%' and actor_id = 'aaaaaaaa-4000-0000-0000-000000000003'),
  '0 | admin.featured_added,admin.featured_moved,admin.featured_period_set,admin.featured_removed');

-- Lecture ouverte aux visiteurs.
select test.check('Explorer sans compte : lecture permise',
  (select has_function_privilege('anon', 'public.public_featured_events(integer)', 'execute')::text
   || ',' || has_table_privilege('anon', 'public.featured_events', 'select')::text),
  'true,false');
set role authenticated;
