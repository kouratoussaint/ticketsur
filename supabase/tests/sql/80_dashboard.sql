-- =============================================================================
-- TicketSûr — Tests : tableau de bord en direct (migration 1300)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1300-0000-0000-000000000001', 'proprio-tdb@test.local'),
  ('aaaaaaaa-1300-0000-0000-000000000002', 'controle-tdb@test.local'),
  ('aaaaaaaa-1300-0000-0000-000000000003', 'autre-tdb@test.local');

set role authenticated;
select test.login('aaaaaaaa-1300-0000-0000-000000000001');
select (public.create_organization('Tableau Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert tableau', now() + interval '1 hour',
                            now() + interval '5 hours', 'Africa/Ouagadougou',
                            null, 100)).id as evt \gset
select set_config('test.dash_evt', :'evt', false) \gset ignored_
select (public.create_ticket_category(:'evt', 'VIP', 10)).id as cat_vip \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as cat_std \gset
select (public.create_checkpoint(:'evt', 'Porte A')).id as cp_a \gset
select (public.create_checkpoint(:'evt', 'Porte B')).id as cp_b \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_

-- Événement sans ticket ni scan ------------------------------------------------
select public.event_dashboard(:'evt')::text as dash \gset
select test.check('Vide : compteurs de tickets à zéro',
  (:'dash'::jsonb->'tickets')::text,
  '{"issued": 0, "expired": 0, "revoked": 0, "admitted": 0, "remaining": 0, "invitations": 0, "invitations_admitted": 0}');
select test.check('Vide : aucune tentative, aucun refus par motif',
  (:'dash'::jsonb->'scans'->>'total') || ' ' || (:'dash'::jsonb->'scans'->'by_outcome')::text,
  '0 {}');
select test.check('Vide : chronologie vide, sans pas',
  (:'dash'::jsonb->'timeline')::text, '{"buckets": [], "step_minutes": null}');
select test.check('Vide : catégories, portes et capacité',
  jsonb_array_length(:'dash'::jsonb->'categories') || ','
  || jsonb_array_length(:'dash'::jsonb->'checkpoints') || ','
  || (:'dash'::jsonb->>'capacity') || ',' || (:'dash'::jsonb->>'status'),
  '2,2,100,published');
select test.check('Vide : contrôle pas encore démarré',
  (:'dash'::jsonb->>'control_open') || ',' || coalesce(:'dash'::jsonb->>'scan_opens_at', '∅')
  || ',' || coalesce(:'dash'::jsonb->>'scan_closes_at', '∅'),
  'false,∅,∅');

-- Scénario : 2 VIP, 3 Standard dont 1 annulé, 5 scans --------------------------
create temp table dash_vip as select * from public.issue_tickets(:'evt', :'cat_vip', 2);
create temp table dash_std as select * from public.issue_tickets(:'evt', :'cat_std', 3);
select qr_token as vip1 from dash_vip order by public_reference limit 1 \gset
select qr_token as std1 from dash_std order by public_reference limit 1 \gset
select ticket_id as std_rev, qr_token as std_rev_tok
from dash_std order by public_reference desc limit 1 \gset
select public.revoke_ticket(:'std_rev', 'Test tableau') \gset ignored_

reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-1300-0000-0000-000000000002', 'controller');
set role authenticated;
select public.assign_member(:'evt', 'aaaaaaaa-1300-0000-0000-000000000002') \gset ignored_
select public.set_event_status(:'evt', 'in_progress') \gset ignored_
select test.check('Contrôle démarré : ouvert et horodaté',
  (public.event_dashboard(:'evt')->>'control_open')
  || ',' || ((public.event_dashboard(:'evt')->>'scan_opens_at') is not null)::text,
  'true,true');

select test.login('aaaaaaaa-1300-0000-0000-000000000002');
select (public.validate_scan('00000000-0000-4000-8000-000000001301', :'evt', :'cp_a', :'vip1'))->>'result' as s1 \gset
select (public.validate_scan('00000000-0000-4000-8000-000000001302', :'evt', :'cp_b', :'vip1'))->>'result' as s2 \gset
select (public.validate_scan('00000000-0000-4000-8000-000000001303', :'evt', :'cp_b', :'std1'))->>'result' as s3 \gset
select (public.validate_scan('00000000-0000-4000-8000-000000001304', :'evt', :'cp_a',
        'TS1.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'))->>'result' as s4 \gset
select (public.validate_scan('00000000-0000-4000-8000-000000001305', :'evt', :'cp_a', :'std_rev_tok'))->>'result' as s5 \gset
select test.check('Scénario : 5 scans joués',
  concat_ws(',', :'s1', :'s2', :'s3', :'s4', :'s5'),
  'accepted,already_used,accepted,not_found,revoked');

-- Droits : seuls propriétaires et gestionnaires --------------------------------
do $$
begin
  perform public.event_dashboard(current_setting('test.dash_evt')::uuid);
  raise exception 'ÉCHEC  tableau accessible à un contrôleur';
exception when insufficient_privilege then
  if sqlerrm <> 'event_not_found' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Contrôleur : tableau refusé (event_not_found)';
end $$;

select test.login('aaaaaaaa-1300-0000-0000-000000000003');
do $$
begin
  perform public.event_dashboard(current_setting('test.dash_evt')::uuid);
  raise exception 'ÉCHEC  tableau accessible à une autre organisation';
exception when insufficient_privilege then
  raise notice 'OK    Autre organisation : tableau refusé';
end $$;

select test.login(null);
do $$
begin
  perform public.event_dashboard(current_setting('test.dash_evt')::uuid);
  raise exception 'ÉCHEC  tableau accessible sans session';
exception when insufficient_privilege then
  raise notice 'OK    Sans session : tableau refusé';
end $$;

-- Propriétaire : compteurs du scénario ----------------------------------------
select test.login('aaaaaaaa-1300-0000-0000-000000000001');
select public.event_dashboard(:'evt')::text as dash \gset

select test.check('Tickets : 4 émis (annulé exclu), 2 entrés, 2 restants, 1 annulé',
  (:'dash'::jsonb->'tickets')::text,
  '{"issued": 4, "expired": 0, "revoked": 1, "admitted": 2, "remaining": 2, "invitations": 0, "invitations_admitted": 0}');
select test.check('Scans : 5 tentatives, 2 acceptées, 3 refusées, 2 entrées récentes',
  concat_ws(',', :'dash'::jsonb->'scans'->>'total', :'dash'::jsonb->'scans'->>'accepted',
            :'dash'::jsonb->'scans'->>'refused', :'dash'::jsonb->'scans'->>'recent_accepted',
            :'dash'::jsonb->'scans'->>'recent_minutes'),
  '5,2,3,2,15');
select test.check('Scans : refus par motif',
  (:'dash'::jsonb->'scans'->'by_outcome')::text,
  '{"revoked": 1, "not_found": 1, "already_used": 1}');
select test.check('Scans : heures du dernier scan et de la dernière entrée renseignées',
  ((:'dash'::jsonb->'scans'->>'last_at') is not null
   and (:'dash'::jsonb->'scans'->>'last_accepted_at') is not null)::text, 'true');
select test.check('Catégories : émis et entrés par catégorie, quota',
  (select string_agg(c->>'name' || ':' || (c->>'issued') || '/' || (c->>'admitted')
                     || '/' || coalesce(c->>'capacity', '∞'), ',' order by c->>'name')
   from jsonb_array_elements(:'dash'::jsonb->'categories') c),
  'Standard:2/1/∞,VIP:2/1/10');
select test.check('Portes : entrées (tickets) et refus (journal) par porte',
  (select string_agg(c->>'name' || ':' || (c->>'admitted') || '/' || (c->>'refused')
                     || '/' || (c->>'active'), ',' order by c->>'name')
   from jsonb_array_elements(:'dash'::jsonb->'checkpoints') c),
  'Porte A:1/2/true,Porte B:1/1/true');
select test.check('Contrôleurs : nom affiché et activité',
  (select string_agg(c->>'display_name' || ':' || (c->>'accepted') || '/' || (c->>'refused'), ',')
   from jsonb_array_elements(:'dash'::jsonb->'controllers') c),
  'controle-tdb:2/3');
select test.check('Chronologie : pas de 5 min, totaux cohérents',
  (:'dash'::jsonb->'timeline'->>'step_minutes') || ','
  || (select sum((b->>'accepted')::int) || '/' || sum((b->>'refused')::int)
      from jsonb_array_elements(:'dash'::jsonb->'timeline'->'buckets') b),
  '5,2/3');
select test.check('Chronologie : tranches alignées sur le pas',
  (select bool_and(extract(minute from (b->>'at')::timestamptz)::int % 5 = 0
                   and extract(second from (b->>'at')::timestamptz) = 0)::text
   from jsonb_array_elements(:'dash'::jsonb->'timeline'->'buckets') b),
  'true');
select test.check('Aucun jeton ni référence de ticket dans le tableau',
  (position('TS1.' in :'dash') + position('"TS-' in :'dash'))::text, '0');

-- Chronologie longue : 9 h de contrôle → pas de 15 min, 48 tranches au plus ---
reset role;
insert into public.events (id, organization_id, title, starts_at, ends_at, status,
                           control_started_at)
values ('aaaaaaaa-1300-0000-0000-0000000000e2', :'org', 'Festival tableau',
        now() + interval '1 hour', now() + interval '5 hours', 'in_progress',
        now() - interval '11 hours');
insert into public.ticket_categories (id, event_id, name)
values ('aaaaaaaa-1300-0000-0000-0000000000c2', 'aaaaaaaa-1300-0000-0000-0000000000e2', 'Pass');
-- Une tentative acceptée porte toujours son ticket (invariant global).
insert into public.tickets (id, event_id, category_id, public_reference, status,
                            redeemed_at, redeemed_by) values
  ('aaaaaaaa-1300-0000-0000-0000000000a1', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   'aaaaaaaa-1300-0000-0000-0000000000c2', 'TS-TDB0-0001', 'redeemed',
   now() - interval '9 hours', 'aaaaaaaa-1300-0000-0000-000000000001'),
  ('aaaaaaaa-1300-0000-0000-0000000000a2', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   'aaaaaaaa-1300-0000-0000-0000000000c2', 'TS-TDB0-0002', 'redeemed',
   now(), 'aaaaaaaa-1300-0000-0000-000000000001');
insert into public.scan_attempts (actor_id, event_id, ticket_id, outcome, server_time) values
  ('aaaaaaaa-1300-0000-0000-000000000001', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   'aaaaaaaa-1300-0000-0000-0000000000a1', 'accepted', now() - interval '9 hours'),
  ('aaaaaaaa-1300-0000-0000-000000000001', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   null, 'not_found', now() - interval '4 hours'),
  ('aaaaaaaa-1300-0000-0000-000000000001', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   'aaaaaaaa-1300-0000-0000-0000000000a2', 'accepted', now()),
  -- Avant le démarrage du contrôle : compté dans les totaux, pas dans la chronologie.
  ('aaaaaaaa-1300-0000-0000-000000000001', 'aaaaaaaa-1300-0000-0000-0000000000e2',
   null, 'event_inactive', now() - interval '2 days');
set role authenticated;
select test.login('aaaaaaaa-1300-0000-0000-000000000001');
select public.event_dashboard('aaaaaaaa-1300-0000-0000-0000000000e2')::text as long_dash \gset
select test.check('Chronologie longue : pas de 15 min, 48 tranches au plus',
  (:'long_dash'::jsonb->'timeline'->>'step_minutes') || ','
  || (jsonb_array_length(:'long_dash'::jsonb->'timeline'->'buckets') <= 48)::text,
  '15,true');
select test.check('Chronologie longue : tentatives hors fenêtre exclues, totaux inclus',
  (select sum((b->>'accepted')::int) || '/' || sum((b->>'refused')::int)
   from jsonb_array_elements(:'long_dash'::jsonb->'timeline'->'buckets') b)
  || ',' || (:'long_dash'::jsonb->'scans'->>'total'),
  '2/1,4');
select test.check('Chronologie longue : tranches contiguës de 15 min',
  (select bool_and(gap = interval '15 minutes')::text
   from (select (b->>'at')::timestamptz
                - lag((b->>'at')::timestamptz) over (order by (b->>'at')::timestamptz) as gap
         from jsonb_array_elements(:'long_dash'::jsonb->'timeline'->'buckets') b) g
   where gap is not null),
  'true');

-- Gestionnaire : accès autorisé ------------------------------------------------
reset role;
update public.organization_members set role = 'manager'
where organization_id = :'org' and user_id = 'aaaaaaaa-1300-0000-0000-000000000002';
set role authenticated;
select test.login('aaaaaaaa-1300-0000-0000-000000000002');
select test.check('Gestionnaire : tableau accessible',
  (public.event_dashboard(:'evt')->'tickets'->>'admitted'), '2');

reset role;
drop table if exists dash_vip;
drop table if exists dash_std;
