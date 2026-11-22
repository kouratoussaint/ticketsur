-- =============================================================================
-- Tikéo — Tests : structure fermée en consultation seule (migration 5400)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-5400-0000-0000-000000000001', 'proprio-fermee@test.local', now()),
  ('aaaaaaaa-5400-0000-0000-000000000002', 'gestion-fermee@test.local', now()),
  ('aaaaaaaa-5400-0000-0000-000000000003', 'controle-fermee@test.local', now()),
  ('aaaaaaaa-5400-0000-0000-000000000004', 'autre-fermee@test.local', now());

-- Une structure qui a servi (un événement, 3 tickets dont 1 entré, 1 annulé
-- de plus) et une structure ouverte du même propriétaire.
set role authenticated;
select test.login('aaaaaaaa-5400-0000-0000-000000000001');
select (public.create_organization('Kwabo Archives Xq')::jsonb)->>'id' as org_closed \gset
select (public.create_organization('Kwabo Ouverte Xq')::jsonb)->>'id' as org_open \gset
select (public.create_event(:'org_closed', 'Festival archivé Xq', now() + interval '5 days',
                            now() + interval '5 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select count(*) from public.issue_tickets(:'ev', :'cat', 4) \gset ignored_
reset role;
with picked as (select t.id from public.tickets t where t.event_id = :'ev' order by t.id limit 1)
update public.tickets t set status = 'redeemed', redeemed_at = now(),
       redeemed_by = 'aaaaaaaa-5400-0000-0000-000000000001', entries_used = 1
 where t.id in (select id from picked);
with picked as (select t.id from public.tickets t
                 where t.event_id = :'ev' and t.status = 'issued' order by t.id limit 1)
update public.tickets t set status = 'revoked', revoked_at = now(),
       revoked_by = 'aaaaaaaa-5400-0000-0000-000000000001'
 where t.id in (select id from picked);
insert into public.organization_members (organization_id, user_id, role) values
  (:'org_closed', 'aaaaaaaa-5400-0000-0000-000000000002', 'manager'),
  (:'org_closed', 'aaaaaaaa-5400-0000-0000-000000000003', 'controller');
-- Fermeture (comme `admin_delete_organization` en mode « close »).
update public.organizations o set status = 'disabled', disabled_at = now(),
       disabled_reason = 'Test', closed_at = now()
 where o.id = :'org_closed';
set role authenticated;

-- Propriétaire ------------------------------------------------------------------
select test.login('aaaaaaaa-5400-0000-0000-000000000001');
select test.check('Propriétaire : une structure fermée listée (pas l''ouverte)',
  (select string_agg(x->>'name' || ':' || (x->>'role') || ':' || (x->>'events'), ',')
     from jsonb_array_elements(public.my_closed_organizations()) x),
  'Kwabo Archives Xq:owner:1');
select test.check('Propriétaire : structure fermée absente de ses structures actives',
  (select count(*)::text from public.my_organizations() o where o.id = :'org_closed'), '0');
select test.check('Événements de la structure fermée : chiffres',
  (select (x->>'title') || ':' || (x->>'issued') || ':' || (x->>'admitted') || ':' || (x->>'revoked')
     from jsonb_array_elements(public.closed_organization_events(:'org_closed')->'events') x),
  'Festival archivé Xq:3:1:1');
select test.check('Fiche de la structure fermée : rôle et date',
  (select (j->'organization'->>'role') || ':' || ((j->'organization'->>'closed_at') is not null)::text
     from (select public.closed_organization_events(:'org_closed') j) s),
  'owner:true');
select test.check('Tableau de bord en consultation',
  (public.closed_event_dashboard(:'ev') is not null)::text, 'true');
select test.check('Bilan en consultation',
  (public.closed_event_summary(:'ev') is not null)::text, 'true');
select test.check('Liste des tickets en consultation (4 lignes, annulé compris)',
  (select count(*)::text from public.closed_event_report_rows(:'ev')), '4');
select test.check('Réglage de consultation retiré après chaque lecture',
  coalesce(current_setting('tikeo.closed_read', true), ''), '');
select test.expect_error('Tableau de bord ordinaire toujours refusé',
  format('select public.event_dashboard(%L)', :'ev'), 'event_not_found');
select test.expect_error('Émission de tickets refusée',
  format('select * from public.issue_tickets(%L, %L, 1)', :'ev', :'cat'), 'Événement introuvable ou droits insuffisants',
  null, :'ev');
select test.expect_error('Structure ouverte : pas une structure fermée',
  format('select public.closed_organization_events(%L)', :'org_open'), 'organization_not_found');

-- Gestionnaire -------------------------------------------------------------------
select test.login('aaaaaaaa-5400-0000-0000-000000000002');
select test.check('Gestionnaire : structure fermée listée',
  (select string_agg(x->>'role', ',') from jsonb_array_elements(public.my_closed_organizations()) x),
  'manager');
select test.check('Gestionnaire : liste des tickets',
  (select count(*)::text from public.closed_event_report_rows(:'ev')), '4');

-- Contrôleur et inconnu : rien -------------------------------------------------------
select test.login('aaaaaaaa-5400-0000-0000-000000000003');
select test.check('Contrôleur : aucune structure fermée',
  jsonb_array_length(public.my_closed_organizations())::text, '0');
select test.expect_error('Contrôleur : événements refusés',
  format('select public.closed_organization_events(%L)', :'org_closed'), 'organization_not_found');
select test.expect_error('Contrôleur : tableau de bord refusé',
  format('select public.closed_event_dashboard(%L)', :'ev'), 'event_not_found');
select test.login('aaaaaaaa-5400-0000-0000-000000000004');
select test.expect_error('Inconnu : liste des tickets refusée',
  format('select * from public.closed_event_report_rows(%L)', :'ev'), 'event_not_found');
select test.expect_error('Inconnu : bilan refusé',
  format('select public.closed_event_summary(%L)', :'ev'), 'event_not_found');

-- Structure à la corbeille : plus consultable ------------------------------------------
reset role;
update public.organizations o set trashed_at = now() where o.id = :'org_closed';
set role authenticated;
select test.login('aaaaaaaa-5400-0000-0000-000000000001');
select test.check('Corbeille : plus listée',
  jsonb_array_length(public.my_closed_organizations())::text, '0');
select test.expect_error('Corbeille : événements refusés',
  format('select public.closed_organization_events(%L)', :'org_closed'), 'organization_not_found');
reset role;
