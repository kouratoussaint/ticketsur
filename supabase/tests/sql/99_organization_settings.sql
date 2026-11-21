-- =============================================================================
-- Tikéo — Tests : réglages de la structure (migration 4600)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4600-0000-0000-000000000001', 'proprio-reglages@test.local'),
  ('aaaaaaaa-4600-0000-0000-000000000002', 'gestion-reglages@test.local'),
  ('aaaaaaaa-4600-0000-0000-000000000003', 'controle-reglages@test.local'),
  ('aaaaaaaa-4600-0000-0000-000000000004', 'autre-reglages@test.local');

set role authenticated;
select test.login('aaaaaaaa-4600-0000-0000-000000000001');
select (public.create_organization('Studio Réglages Qzw')::jsonb)->>'id' as org \gset

select test.check('Sans réglage : messages vides, aucune proposition',
  (select coalesce(s->>'ticket_message', '-') || ':' || jsonb_array_length(s->'default_categories')
          || ':' || jsonb_array_length(s->'default_checkpoints')
     from public.organization_settings(:'org') s),
  '-:0:0');

select public.update_organization_settings(:'org',
  '  Bonjour {prenom}, voici votre ticket pour {evenement}.  ', null,
  'Africa/Abidjan', '  Bobo-Dioulasso ', 'concert',
  jsonb_build_array(
    jsonb_build_object('name', ' Standard ', 'capacity', 500, 'price', 2000),
    jsonb_build_object('name', 'VIP', 'capacity', 50, 'price', 10000),
    jsonb_build_object('name', 'Invités', 'invitation', true)),
  jsonb_build_array('Entrée principale', 'Entrée VIP')) \gset ignored_

select test.check('Réglages relus, textes nettoyés',
  (select (s->>'ticket_message') || '|' || coalesce(s->>'invitation_message', '-') || '|'
          || (s->>'default_timezone') || '|' || (s->>'default_city') || '|' || (s->>'default_kind')
          || '|' || (s->'default_categories'->0->>'name') || '|'
          || (s->'default_categories'->2->>'invitation') || '|' || (s->'default_checkpoints'->>1)
     from public.organization_settings(:'org') s),
  'Bonjour {prenom}, voici votre ticket pour {evenement}.|-|Africa/Abidjan|Bobo-Dioulasso|concert|Standard|true|Entrée VIP');

-- Validations.
select test.expect_error('Fuseau inconnu',
  format($q$select public.update_organization_settings(%L, null, null, 'Mars/Olympus', null, null, null, null)$q$, :'org'),
  'settings_timezone_invalid');
select test.expect_error('Type inconnu',
  format($q$select public.update_organization_settings(%L, null, null, null, null, 'rodeo', null, null)$q$, :'org'),
  'settings_kind_invalid');
select test.expect_error('Message trop long',
  format($q$select public.update_organization_settings(%L, repeat('a', 601), null, null, null, null, null, null)$q$, :'org'),
  'settings_message_invalid');
select test.expect_error('Catégories en double (majuscules)',
  format($q$select public.update_organization_settings(%L, null, null, null, null, null,
    '[{"name":"VIP"},{"name":"vip"}]'::jsonb, null)$q$, :'org'),
  'settings_categories_invalid');
select test.expect_error('Prix négatif',
  format($q$select public.update_organization_settings(%L, null, null, null, null, null,
    '[{"name":"VIP","price":-5}]'::jsonb, null)$q$, :'org'),
  'settings_categories_invalid');
select test.expect_error('Quota illisible',
  format($q$select public.update_organization_settings(%L, null, null, null, null, null,
    '[{"name":"VIP","capacity":"beaucoup"}]'::jsonb, null)$q$, :'org'),
  'settings_categories_invalid');
select test.expect_error('Plus de 10 portes',
  format($q$select public.update_organization_settings(%L, null, null, null, null, null, null,
    (select jsonb_agg('Porte ' || g) from generate_series(1, 11) g))$q$, :'org'),
  'settings_checkpoints_invalid');
select test.expect_error('Porte vide',
  format($q$select public.update_organization_settings(%L, null, null, null, null, null, null,
    '["  "]'::jsonb)$q$, :'org'),
  'settings_checkpoints_invalid');
select test.check('Réglages inchangés après les refus',
  (select jsonb_array_length(s->'default_categories')::text from public.organization_settings(:'org') s),
  '3');

-- Propositions appliquées à un événement : seulement les noms absents.
select (public.create_event(:'org', 'Concert des réglages Qzw', now() + interval '6 days',
                            now() + interval '6 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'vip')).id as existing \gset
select test.check('Catégories et portes ajoutées (VIP déjà là)',
  (select (r->>'categories') || ':' || (r->>'checkpoints') from public.apply_event_defaults(:'ev') r),
  '2:2');
select test.check('Catégorie proposée avec quota, prix et invitation',
  (select string_agg(c.name || '/' || coalesce(c.capacity::text, '-') || '/'
                     || coalesce(c.indicative_price::text, '-') || '/' || c.is_invitation,
                     ',' order by c.name collate "C")
     from public.ticket_categories c where c.event_id = :'ev'),
  'Invités/-/-/true,Standard/500/2000/false,vip/-/-/false');
select test.check('Deuxième application : rien de plus',
  (select (r->>'categories') || ':' || (r->>'checkpoints') from public.apply_event_defaults(:'ev') r),
  '0:0');

-- Gestionnaire : lecture et écriture ; contrôleur et autre compte : refusés.
reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-4600-0000-0000-000000000002', 'manager'),
  (:'org', 'aaaaaaaa-4600-0000-0000-000000000003', 'controller');
set role authenticated;
select test.login('aaaaaaaa-4600-0000-0000-000000000002');
select public.update_organization_settings(:'org', null, 'Vous êtes invité(e) à {evenement}.',
  null, null, null, '[]'::jsonb, '[]'::jsonb) \gset ignored_
select test.check('Gestionnaire : réglage remplacé',
  (select coalesce(s->>'ticket_message', '-') || '|' || (s->>'invitation_message') || '|'
          || coalesce(s->>'default_city', '-') || '|' || jsonb_array_length(s->'default_categories')
     from public.organization_settings(:'org') s),
  '-|Vous êtes invité(e) à {evenement}.|-|0');
select test.login('aaaaaaaa-4600-0000-0000-000000000003');
select test.expect_error('Contrôleur : lecture refusée',
  format($q$select public.organization_settings(%L)$q$, :'org'), 'organization_not_found');
select test.expect_error('Contrôleur : propositions refusées',
  format($q$select public.apply_event_defaults(%L)$q$, :'ev'), 'event_not_found');
select test.login('aaaaaaaa-4600-0000-0000-000000000004');
select test.expect_error('Autre compte : écriture refusée',
  format($q$select public.update_organization_settings(%L, 'x', null, null, null, null, null, null)$q$, :'org'),
  'organization_not_found');

-- Journal : jamais le texte des messages.
reset role;
select test.check('Journal : indicateurs seulement',
  (select count(*) || ':' || bool_and(a.details::text not like '%prenom%'
                                      and a.details::text not like '%invité(e)%')
     from public.audit_logs a
    where a.action = 'organization.settings_updated' and a.organization_id = :'org'),
  '2:true');
select test.check('Réglages fermés à l''API',
  (has_table_privilege('authenticated', 'public.organization_settings', 'select'))::text, 'false');
