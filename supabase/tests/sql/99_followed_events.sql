-- =============================================================================
-- Tikéo — Tests : événements des structures suivies (migration 5900)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5900-0000-0000-000000000001', 'proprio-fil@test.local', now()),
  ('aaaaaaaa-5900-0000-0000-000000000002', 'abonne-fil@test.local', now()),
  ('aaaaaaaa-5900-0000-0000-000000000003', 'autre-fil@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-5900-0000-0000-000000000001');
select (public.create_organization('Fil Prod Yq')::jsonb)->>'id' as org \gset
select (public.create_organization('Autre Prod Yq')::jsonb)->>'id' as org2 \gset
select (public.create_event(:'org', 'Concert Yq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as e_late \gset
select (public.create_event(:'org', 'Gala Yq', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as e_soon \gset
select (public.create_event(:'org', 'Privé Yq', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as e_priv \gset
select (public.create_event(:'org', 'Brouillon Yq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as e_draft \gset
select (public.create_event(:'org2', 'Ailleurs Yq', now() + interval '1 day',
                            now() + interval '1 day 4 hours')).id as e_other \gset
select (public.create_ticket_category(:'e_late', 'Standard')).id as c_std \gset
select public.set_category_price(:'c_std', 2500) \gset ignored_
select test.complete_event(:'e_late') \gset ignored_
select test.complete_event(:'e_soon') \gset ignored_
select test.complete_event(:'e_priv') \gset ignored_
select test.complete_event(:'e_other') \gset ignored_
select public.set_event_status(:'e_late', 'published') \gset ignored_
select public.set_event_status(:'e_soon', 'published') \gset ignored_
select public.set_event_status(:'e_priv', 'published') \gset ignored_
select public.set_event_status(:'e_other', 'published') \gset ignored_
select public.set_event_public(:'e_priv', false) \gset ignored_

-- Sans suivi : rien ----------------------------------------------------------------
select test.login('aaaaaaaa-5900-0000-0000-000000000002');
select test.check('Aucune structure suivie : liste vide',
  (select count(*)::text from public.my_followed_events()), '0');

-- Suivi : événements publics de la structure, du plus proche au plus lointain --------
select public.follow_organization(:'org', true) \gset ignored_
select test.check('Événements listés seulement, par date',
  (select string_agg(title, ',' order by starts_at) from public.my_followed_events()),
  'Gala Yq,Concert Yq');
select test.check('Champs de vitrine : structure et prix indicatif',
  (select organization_name || '|' || min_price from public.my_followed_events()
    where id = :'e_late'),
  'Fil Prod Yq|2500');
select test.check('Limite respectée',
  (select count(*)::text from public.my_followed_events(1)), '1');

-- Un autre compte ne voit pas les suivis du premier ---------------------------------
select test.login('aaaaaaaa-5900-0000-0000-000000000003');
select test.check('Autre compte : liste vide',
  (select count(*)::text from public.my_followed_events()), '0');

-- Ne plus suivre ; structure suspendue ------------------------------------------------
select test.login('aaaaaaaa-5900-0000-0000-000000000002');
select public.follow_organization(:'org2', true) \gset ignored_
select public.follow_organization(:'org', false) \gset ignored_
select test.check('Ne plus suivre : seulement l''autre structure',
  (select string_agg(title, ',') from public.my_followed_events()), 'Ailleurs Yq');
reset role;
update public.organizations set status = 'disabled', disabled_at = now(),
       disabled_reason = 'Test' where id = :'org2';
set role authenticated;
select test.login('aaaaaaaa-5900-0000-0000-000000000002');
select test.check('Structure suspendue : plus rien',
  (select count(*)::text from public.my_followed_events()), '0');
reset role;
select test.check('Fermée aux visiteurs',
  has_function_privilege('anon', 'public.my_followed_events(integer)', 'execute')::text,
  'false');
