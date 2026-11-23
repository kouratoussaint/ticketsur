-- =============================================================================
-- Tikéo — Tests : vues uniques de la fiche publique (migration 6200)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6200-0000-0000-000000000001', 'proprio-uniques@test.local', now()),
  ('aaaaaaaa-6200-0000-0000-000000000002', 'fan-uniques@test.local', now());

set role authenticated;
select test.login('aaaaaaaa-6200-0000-0000-000000000001');
select (public.create_organization('Uniques Prod Tq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Tq', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
-- Le propriétaire qui ouvre sa propre fiche ne compte pas.
select public.record_event_view(:'ev', 'proprio-appareil-0001');
reset role;
select test.check('Membre de la structure : pas compté',
  (select coalesce(sum(views), 0)::text from public.event_page_views where event_id = :'ev'), '0');

-- Même appareil : une seule vue ; autre appareil : une de plus ----------------------
select test.login(null);
set role anon;
select set_config('request.headers', '{"x-forwarded-for": "198.51.100.7, 10.0.0.1"}', false) \gset ignored_
select public.record_event_view(:'ev', 'appareil-aaaa-0001');
select public.record_event_view(:'ev', 'appareil-aaaa-0001');
select public.record_event_view(:'ev', 'appareil-aaaa-0001');
select public.record_event_view(:'ev', 'appareil-bbbb-0002');
reset role;
select test.check('Rappels du même appareil : une seule vue',
  (select views::text from public.event_page_views where event_id = :'ev'), '2');

-- Compte connecté : compté une fois, quel que soit l'appareil annoncé ------------------
set role authenticated;
select test.login('aaaaaaaa-6200-0000-0000-000000000002');
select public.record_event_view(:'ev', 'appareil-cccc-0003');
select public.record_event_view(:'ev', 'appareil-dddd-0004');
select public.record_event_view(:'ev');
reset role;
select test.check('Compte connecté : une seule vue',
  (select views::text from public.event_page_views where event_id = :'ev'), '3');

-- Numéros inventés à chaque appel : 20 vues au plus par adresse ----------------------
select test.login(null);
set role anon;
select set_config('request.headers', '{"x-forwarded-for": "203.0.113.9"}', false) \gset ignored_
select count(public.record_event_view(:'ev', 'faux-appareil-' || lpad(i::text, 6, '0')))
  from generate_series(1, 30) i \gset ignored_
-- Ancienne APK (sans numéro) : l'adresse sert de visiteur.
select set_config('request.headers', '{"x-forwarded-for": "192.0.2.44"}', false) \gset ignored_
select public.record_event_view(:'ev');
select public.record_event_view(:'ev');
-- Numéro invalide : traité comme sans numéro.
select public.record_event_view(:'ev', 'x');
reset role;
select test.check('20 vues au plus par adresse ; ancienne APK : une vue',
  (select views::text from public.event_page_views where event_id = :'ev'), '24');

-- Rien en clair, et purge -------------------------------------------------------------
select test.check('Empreintes seulement (32 octets), rien en clair',
  (select bool_and(octet_length(viewer) = 32)::text from private.event_view_seen
    where event_id = :'ev')
  || '|' || (select count(*)::text from private.event_view_seen s
              where s.event_id = :'ev'
                and (encode(s.viewer, 'escape') like '%appareil%'
                     or encode(s.viewer, 'escape') like '%203.0.113.9%')),
  'true|0');
update private.event_view_seen set day = day - 1 where event_id = :'ev';
update private.event_view_networks set day = day - 1 where event_id = :'ev';
select private.purge_view_keys() \gset ignored_
select test.check('Purge : empreintes de la veille effacées, compteur gardé',
  (select count(*)::text from private.event_view_seen where event_id = :'ev')
  || '|' || (select count(*)::text from private.event_view_networks where event_id = :'ev')
  || '|' || (select views::text from public.event_page_views where event_id = :'ev'),
  '0|0|24');
select test.check('Tables des empreintes fermées à l''API',
  has_table_privilege('anon', 'private.event_view_seen', 'select')::text, 'false');
select set_config('request.headers', '', false) \gset ignored_
