-- =============================================================================
-- Tikéo — Tests : suivre une structure, présentation et réseaux (migration 5700)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5700-0000-0000-000000000001', 'proprio-suivi@test.local', now()),
  ('aaaaaaaa-5700-0000-0000-000000000002', 'abonne-suivi@test.local', now()),
  ('aaaaaaaa-5700-0000-0000-000000000003', 'gestion-suivi@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-5700-0000-0000-000000000001');
select (public.create_organization('Suivi Prod Wq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Festival Wq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select test.complete_event(:'ev') \gset ignored_
reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-5700-0000-0000-000000000003', 'manager');
set role authenticated;

-- Présentation et réseaux (propriétaire) ---------------------------------------
select test.login('aaaaaaaa-5700-0000-0000-000000000001');
select public.set_organization_profile(:'org', '  Concerts et festivals à Ouaga.  ',
  'https://www.facebook.com/suiviprod', 'https://instagram.com/suiviprod', null) \gset ignored_
select test.check('Présentation et réseaux enregistrés',
  (select public_description || '|' || facebook_url || '|' || instagram_url || '|'
          || coalesce(tiktok_url, '∅')
     from public.my_organizations() where id = :'org'),
  'Concerts et festivals à Ouaga.|https://www.facebook.com/suiviprod|https://instagram.com/suiviprod|∅');
select test.check('Journal : noms des champs seulement',
  (select details::text from public.organization_audit_logs(:'org', array['organization.profile'], 10, 0)
    limit 1),
  '{"fields": ["description", "facebook", "instagram"]}');
select test.expect_error('Lien d''un autre site refusé',
  format('select public.set_organization_profile(%L, null, %L, null, null)', :'org',
         'https://exemple.com/suiviprod'),
  'org_link_invalid');
select test.expect_error('Présentation trop longue refusée',
  format('select public.set_organization_profile(%L, %L, null, null, null)', :'org',
         repeat('a', 601)),
  'org_description_invalid');
select test.login('aaaaaaaa-5700-0000-0000-000000000003');
select test.expect_error('Gestionnaire : présentation réservée au propriétaire',
  format('select public.set_organization_profile(%L, %L, null, null, null)', :'org', 'X'),
  'org_not_found');

-- Suivre --------------------------------------------------------------------------
select public.follow_organization(:'org', true) \gset ignored_
select test.login('aaaaaaaa-5700-0000-0000-000000000002');
select test.check('Suivre : état et nombre d''abonnés',
  public.follow_organization(:'org', true)::text, '{"followers": 2, "following": true}');
select test.check('Suivre deux fois : sans effet',
  public.follow_organization(:'org', true)->>'followers', '2');
select test.check('Page publique : suivie, présentation, réseaux',
  (select (j->>'following') || '|' || (j->>'followers') || '|' || (j->>'description')
          || '|' || (j->>'facebook_url')
     from (select public.public_organization(:'org') j) s),
  'true|2|Concerts et festivals à Ouaga.|https://www.facebook.com/suiviprod');

-- Première mise au catalogue : notification aux abonnés hors membres -------------
select test.login('aaaaaaaa-5700-0000-0000-000000000001');
select public.set_event_status(:'ev', 'published') \gset ignored_
reset role;
select test.check('Abonné prévenu, vers la fiche ; gestionnaire non prévenu',
  (select string_agg(right(user_id::text, 1) || ':' || title || ':' || route, ',')
     from public.push_outbox
    where route = '/evenement/' || :'ev'),
  '2:Nouvel événement : Festival Wq:/evenement/' || :'ev');
set role authenticated;
select test.login('aaaaaaaa-5700-0000-0000-000000000001');
select public.set_event_public(:'ev', false) \gset ignored_
select public.set_event_public(:'ev', true) \gset ignored_
reset role;
select test.check('Rendu privé puis public : pas de seconde notification',
  (select count(*)::text from public.push_outbox where route = '/evenement/' || :'ev'), '1');
set role authenticated;

select test.login('aaaaaaaa-5700-0000-0000-000000000002');
select test.check('Structures suivies : nom et événements à venir',
  (select string_agg((x->>'name') || ':' || (x->>'upcoming'), ',')
     from jsonb_array_elements(public.my_followed_organizations()) x),
  'Suivi Prod Wq:1');
select test.check('Ne plus suivre',
  public.follow_organization(:'org', false)::text, '{"followers": 1, "following": false}');
select test.check('Plus dans les structures suivies',
  jsonb_array_length(public.my_followed_organizations())::text, '0');

-- Visiteur ; structure suspendue ------------------------------------------------------
set role anon;
select public.public_organization(:'org')->>'following' as anon_following \gset
reset role;
select test.check('Visiteur : jamais « suivie »', :'anon_following', 'false');
update public.organizations set status = 'disabled', disabled_at = now(),
       disabled_reason = 'Test' where id = :'org';
set role authenticated;
select test.login('aaaaaaaa-5700-0000-0000-000000000002');
select test.expect_error('Structure suspendue : impossible à suivre',
  format('select public.follow_organization(%L, true)', :'org'), 'organization_not_found');
reset role;
