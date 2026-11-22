-- =============================================================================
-- Tikéo — Tests : page publique d'une structure (migration 5500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5500-0000-0000-000000000001', 'proprio-vitrine@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-5500-0000-0000-000000000001');
select (public.create_organization('Vitrine Prod Zq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Zq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as e_pub \gset
select (public.create_event(:'org', 'Gala Zq', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as e_pub2 \gset
select (public.create_event(:'org', 'Réunion Zq privée', now() + interval '4 days',
                            now() + interval '4 days 4 hours')).id as e_priv \gset
select (public.create_event(:'org', 'Passé Zq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as e_past \gset
select (public.create_event(:'org', 'Brouillon Zq', now() + interval '6 days',
                            now() + interval '6 days 4 hours')).id as e_draft \gset
select (public.create_ticket_category(:'e_pub', 'Standard')).id as c_std \gset
select public.set_category_price(:'c_std', 3000) \gset ignored_
select test.complete_event(:'e_pub') \gset ignored_
select test.complete_event(:'e_pub2') \gset ignored_
select test.complete_event(:'e_priv') \gset ignored_
select test.complete_event(:'e_past') \gset ignored_
select public.set_event_status(:'e_pub', 'published') \gset ignored_
select public.set_event_status(:'e_pub2', 'published') \gset ignored_
select public.set_event_status(:'e_priv', 'published') \gset ignored_
select public.set_event_status(:'e_past', 'published') \gset ignored_
select public.set_event_public(:'e_priv', false) \gset ignored_
select public.set_organization_public_phone(:'org', '+22670000055') \gset ignored_
reset role;
-- Un événement public déjà terminé.
update public.events set starts_at = now() - interval '10 days',
       ends_at = now() - interval '10 days' + interval '4 hours'
 where id = :'e_past';

-- Lu en visiteur, vérifié ensuite (le rôle anon n'a pas accès au schéma test).
set role anon;
select public.public_event(:'e_pub')->'organization'->>'id' as got_org \gset
select public.public_organization(:'org')::text as page \gset
reset role;
select test.check('Fiche d''un événement : identifiant de la structure', :'got_org', :'org');
select test.check('Structure : nom, téléphone public',
  (select (j->>'name') || ':' || (j->>'public_phone') from (select :'page'::jsonb j) s),
  'Vitrine Prod Zq:+22670000055');
select test.check('Structure : événements au catalogue seulement, par date',
  (select string_agg(x->>'title', ',' order by ord)
     from jsonb_array_elements((:'page'::jsonb)->'events') with ordinality as t(x, ord)),
  'Gala Zq,Concert Zq');
select test.check('Structure : prix indicatif',
  (select x->>'min_price' from jsonb_array_elements((:'page'::jsonb)->'events') x
    where x->>'title' = 'Concert Zq'),
  '3000');
select test.check('Structure : événements publics passés comptés',
  (:'page'::jsonb)->>'past_events', '1');
select test.check('Structure : rien de privé (clés exposées)',
  (select string_agg(k, ',' order by k) from jsonb_object_keys(:'page'::jsonb) k),
  'city,created_at,description,events,facebook_url,followers,following,id,instagram_url,'
  || 'logo_path,name,past_events,public_phone,tiktok_url');
reset role;
select test.expect_error('Structure inconnue',
  'select public.public_organization(''00000000-0000-0000-0000-00000000cafe'')',
  'organization_not_found');
update public.organizations set status = 'disabled', disabled_at = now(),
       disabled_reason = 'Test' where id = :'org';
select test.expect_error('Structure suspendue : introuvable',
  format('select public.public_organization(%L)', :'org'), 'organization_not_found');
