-- =============================================================================
-- TicketSûr — Tests : postes du contrôleur et historique (migration 1000)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1000-0000-0000-000000000001', 'proprio-postes@test.local'),
  ('aaaaaaaa-1000-0000-0000-000000000002', 'controle-postes@test.local'),
  ('aaaaaaaa-1000-0000-0000-000000000003', 'autre-postes@test.local');

set role authenticated;
select test.login('aaaaaaaa-1000-0000-0000-000000000001');
select (public.create_organization('Postes Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Soirée postes', now() + interval '1 hour',
                            now() + interval '5 hours')).id as evt \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as cat \gset
select (public.create_checkpoint(:'evt', 'Porte A')).id as cp_a \gset
select (public.create_checkpoint(:'evt', 'Porte B')).id as cp_b \gset
select public.update_checkpoint(:'cp_b', 'Porte B', false) \gset ignored_
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_
select (public.create_event(:'org', 'Brouillon postes', now() + interval '1 day',
                            now() + interval '1 day 2 hours')).id as evt_draft \gset
select (public.create_checkpoint(:'evt_draft', 'Porte D')).id as cp_d \gset
create temp table post_tickets as select * from public.issue_tickets(:'evt', :'cat', 2);
select qr_token as tok1 from post_tickets order by public_reference limit 1 \gset
select public_reference as ref1 from post_tickets order by public_reference limit 1 \gset

reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-1000-0000-0000-000000000002', 'controller');
-- Événement terminé depuis deux jours (fenêtre fermée), affecté.
insert into public.events (id, organization_id, title, starts_at, ends_at, status)
values ('aaaaaaaa-1000-0000-0000-0000000000e3', :'org', 'Passé postes',
        now() - interval '3 days', now() - interval '2 days', 'published');
insert into public.checkpoints (id, event_id, name)
values ('aaaaaaaa-1000-0000-0000-0000000000c3', 'aaaaaaaa-1000-0000-0000-0000000000e3', 'Porte P');
set role authenticated;

select test.login('aaaaaaaa-1000-0000-0000-000000000002');
select test.check('Sans affectation : aucun poste',
  (select count(*) from public.my_scan_posts())::text, '0');

select test.login('aaaaaaaa-1000-0000-0000-000000000001');
select public.assign_member(:'evt', 'aaaaaaaa-1000-0000-0000-000000000002') \gset ignored_
select public.assign_member(:'evt', 'aaaaaaaa-1000-0000-0000-000000000002', :'cp_a') \gset ignored_
select public.assign_member(:'evt_draft', 'aaaaaaaa-1000-0000-0000-000000000002') \gset ignored_
reset role;
insert into public.event_assignments (event_id, user_id)
values ('aaaaaaaa-1000-0000-0000-0000000000e3', 'aaaaaaaa-1000-0000-0000-000000000002');
set role authenticated;

select test.login('aaaaaaaa-1000-0000-0000-000000000002');
select test.check('Postes : porte active seulement, sans doublon, ni brouillon ni passé',
  (select string_agg(event_title || '/' || checkpoint_name, ',') from public.my_scan_posts()),
  'Soirée postes/Porte A');
select test.check('Poste listé avant le démarrage du contrôle',
  (select event_status::text from public.my_scan_posts()), 'published');
select test.check('Contrôle pas démarré : entrée refusée',
  (public.validate_scan('00000000-0000-4000-8000-000000001000', :'evt', :'cp_a', :'tok1'))->>'result',
  'event_inactive');

-- L'organisateur démarre le contrôle (migration 2000).
select test.login('aaaaaaaa-1000-0000-0000-000000000001');
select (public.set_event_status(:'evt', 'in_progress')).control_started_at is not null as started \gset
select test.check('Démarrage du contrôle horodaté', :'started', 't');
select test.login('aaaaaaaa-1000-0000-0000-000000000002');

-- Historique personnel.
select (public.validate_scan('00000000-0000-4000-8000-000000001001', :'evt', :'cp_a', :'tok1'))->>'result' as r1 \gset
select (public.validate_scan('00000000-0000-4000-8000-000000001002', :'evt', :'cp_a', :'tok1'))->>'result' as r2 \gset
select test.check('Scans : accepté puis déjà utilisé', :'r1' || ',' || :'r2', 'accepted,already_used');
-- Ensemble et non ordre : en transaction unique (staging), même horodatage.
select test.check('Historique : les 3 tentatives',
  (select string_agg(outcome::text, ',' order by outcome::text) from public.my_recent_scans()),
  'accepted,already_used,event_inactive');

-- Aucune limite d'heure : un événement terminé depuis deux jours dont le
-- contrôle est en cours reste contrôlable.
reset role;
update public.events set status = 'in_progress', control_started_at = now() - interval '3 days'
 where id = 'aaaaaaaa-1000-0000-0000-0000000000e3';
set role authenticated;
select test.login('aaaaaaaa-1000-0000-0000-000000000002');
select test.check('Contrôle en cours, événement fini depuis 2 jours : poste listé',
  (select count(*)::text from public.my_scan_posts() where event_title = 'Passé postes'), '1');

-- Arrêt du contrôle : plus aucune entrée, même pendant l'événement.
select test.login('aaaaaaaa-1000-0000-0000-000000000001');
select (public.set_event_status(:'evt', 'closed')).control_stopped_at is not null as stopped \gset
select test.check('Arrêt du contrôle horodaté', :'stopped', 't');
select test.login('aaaaaaaa-1000-0000-0000-000000000002');
select test.check('Contrôle arrêté : entrée refusée',
  (public.validate_scan('00000000-0000-4000-8000-000000001003', :'evt', :'cp_a',
     (select qr_token from post_tickets order by public_reference offset 1 limit 1)))->>'result',
  'event_inactive');
select test.check('Contrôle arrêté : poste retiré',
  (select count(*)::text from public.my_scan_posts() where event_title = 'Soirée postes'), '0');
select test.check('Historique : référence, catégorie et porte, sans jeton',
  (select public_reference || '|' || category_name || '|' || checkpoint_name
   from public.my_recent_scans() where outcome = 'accepted'),
  :'ref1' || '|Standard|Porte A');
select test.check('Historique : aucune colonne de jeton',
  (select count(*) from pg_catalog.pg_proc p, unnest(p.proargnames) n
   where p.proname = 'my_recent_scans' and n like '%token%')::text, '0');

select test.login('aaaaaaaa-1000-0000-0000-000000000003');
select test.check('Autre compte : historique et postes vides',
  ((select count(*) from public.my_recent_scans())
   + (select count(*) from public.my_scan_posts()))::text, '0');

-- Désactivation : plus aucun poste.
select test.login('aaaaaaaa-1000-0000-0000-000000000001');
select public.update_member(:'org', 'aaaaaaaa-1000-0000-0000-000000000002', 'controller', false) \gset ignored_
select test.login('aaaaaaaa-1000-0000-0000-000000000002');
select test.check('Contrôleur désactivé : plus aucun poste',
  (select count(*) from public.my_scan_posts())::text, '0');

reset role;
drop table if exists post_tickets;
