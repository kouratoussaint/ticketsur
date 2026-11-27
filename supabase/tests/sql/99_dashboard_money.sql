-- =============================================================================
-- Tikéo — Tests : recettes probables et pertes évitées (migrations 6700, 6800)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-6700-0000-0000-000000000001', 'proprio-recettes@test.local', now()),
  ('aaaaaaaa-6700-0000-0000-000000000002', 'controle-recettes@test.local', now()),
  ('aaaaaaaa-6700-0000-0000-000000000003', 'super-recettes@test.local', now()),
  ('aaaaaaaa-6700-0000-0000-000000000004', 'support-recettes@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-6700-0000-0000-000000000003', 'aaaaaaaa-6700-0000-0000-000000000004');
insert into private.platform_admin_roles (user_id, role)
values ('aaaaaaaa-6700-0000-0000-000000000004', 'support');
-- Délai des doubles scans connu (le staging peut avoir été réglé).
update private.console_settings s set value = '15'::jsonb where s.key = 'double_scan_seconds';

set role authenticated;
select test.login('aaaaaaaa-6700-0000-0000-000000000001');
select (public.create_organization('Recettes Prod Mq')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Mq', now() + interval '1 hour',
                            now() + interval '5 hours')).id as ev \gset
select (public.create_event(:'org', 'Autre Mq', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as ev2 \gset
select (public.create_ticket_category(:'ev', 'VIP')).id as vip \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as std \gset
select (public.create_ticket_category(:'ev', 'Sans prix')).id as nop \gset
select (public.create_ticket_category(:'ev', 'Invités', null, true)).id as inv \gset
select (public.create_ticket_category(:'ev2', 'Standard')).id as std2 \gset
select public.set_category_price(:'vip', 10000) \gset ignored_
select public.set_category_price(:'std', 2000) \gset ignored_
select public.set_category_price(:'inv', 5000) \gset ignored_
select test.complete_event(:'ev') \gset ignored_
select test.complete_event(:'ev2') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select public.set_event_status(:'ev2', 'published') \gset ignored_
select public.set_event_status(:'ev', 'in_progress') \gset ignored_

-- Aucun passage : tout à zéro --------------------------------------------------------
select test.check('Sans passage : zéro, catégories listées',
  (select (m->>'revenue') || '|' || (m->>'avoided') || '|' || jsonb_array_length(m->'categories')
     from (select public.event_dashboard(:'ev')->'money' as m) x),
  '0|0|4');

select array_agg(ticket_id) as vips from public.issue_tickets(:'ev', :'vip', 3) \gset
select array_agg(ticket_id) as stds from public.issue_tickets(:'ev', :'std', 4) \gset
select array_agg(ticket_id) as nops from public.issue_tickets(:'ev', :'nop', 2) \gset
select array_agg(ticket_id) as invs from public.issue_tickets(:'ev', :'inv', 2) \gset
select array_agg(ticket_id) as others from public.issue_tickets(:'ev2', :'std2', 1) \gset

reset role;
-- Entrées : 2 VIP, 3 Standard, 1 Sans prix, 2 Invités.
create temporary table entered_mq as
  select unnest(:'vips'::uuid[]) as id, 1 as k limit 2;
insert into entered_mq select unnest(:'stds'::uuid[]), 2 limit 3;
insert into entered_mq select unnest(:'nops'::uuid[]), 3 limit 1;
insert into entered_mq select unnest(:'invs'::uuid[]), 4;
update public.tickets t
   set status = 'redeemed', entries_used = 1, redeemed_at = now() - interval '30 minutes',
       redeemed_by = 'aaaaaaaa-6700-0000-0000-000000000002',
       last_entry_at = now() - interval '30 minutes'
 where t.id in (select id from entered_mq);
insert into public.scan_attempts (actor_id, event_id, ticket_id, outcome, server_time)
select 'aaaaaaaa-6700-0000-0000-000000000002', :'ev', id, 'accepted', now() - interval '30 minutes'
  from entered_mq;

-- Refus : un VIP déjà entré présenté 10 min plus tard (deux fois : compté une fois),
-- un Standard déjà entré repassé 10 s après (double scan sous 15 s : écarté),
-- un Standard annulé, un Sans prix déjà entré, une invitation déjà entrée,
-- un QR inconnu, un ticket d'un autre événement.
update public.tickets set status = 'revoked', revoked_at = now()
 where id = (:'stds'::uuid[])[4];
insert into public.scan_attempts (actor_id, event_id, ticket_id, outcome, server_time) values
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (:'vips'::uuid[])[1], 'already_used', now() - interval '20 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (:'vips'::uuid[])[1], 'already_used', now() - interval '19 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (select id from entered_mq where k = 2 limit 1),
   'already_used', now() - interval '30 minutes' + interval '10 seconds'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (:'stds'::uuid[])[4], 'revoked', now() - interval '5 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (select id from entered_mq where k = 3), 'already_used', now() - interval '4 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (select id from entered_mq where k = 4 limit 1), 'already_used', now() - interval '3 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', null, 'not_found', now() - interval '2 minutes'),
  ('aaaaaaaa-6700-0000-0000-000000000002', :'ev', (:'others'::uuid[])[1], 'wrong_event', now() - interval '1 minute');

set role authenticated;
select test.login('aaaaaaaa-6700-0000-0000-000000000001');
select public.event_dashboard(:'ev')->'money' as money \gset
select test.check('Recettes : 2 × 10 000 + 3 × 2 000 ; 1 entrée sans prix ; invitations à part',
  (:'money'::jsonb->>'revenue') || '|' || (:'money'::jsonb->>'revenue_tickets') || '|'
  || (:'money'::jsonb->>'revenue_unpriced'),
  '26000|5|1');
select test.check('Pertes évitées : VIP déjà entré + Standard annulé ; sans prix à part ; double passage écarté',
  (:'money'::jsonb->>'avoided') || '|' || (:'money'::jsonb->>'avoided_tickets') || '|'
  || (:'money'::jsonb->>'avoided_unpriced') || '|' || (:'money'::jsonb->>'unknown_refusals'),
  '12000|2|1|2');
select test.check('Détail par catégorie',
  (select string_agg((c->>'name') || ':' || (c->>'admitted') || ':' || (c->>'refused') || ':'
                     || coalesce(c->>'revenue', '∅') || ':' || coalesce(c->>'avoided', '∅'), ','
                     order by c->>'name')
     from jsonb_array_elements(:'money'::jsonb->'categories') c),
  'Invités:2:1:0:0,Sans prix:1:1:∅:∅,Standard:3:1:6000:2000,VIP:2:1:20000:10000');
select test.check('Doubles scans : 1 refus écarté, délai de 15 s',
  (:'money'::jsonb->>'double_scans') || '|' || (:'money'::jsonb->>'double_scan_seconds'),
  '1|15');

-- Délai à 0 : le double scan compte ---------------------------------------------------
reset role;
update private.console_settings s set value = '0'::jsonb where s.key = 'double_scan_seconds';
set role authenticated;
select test.login('aaaaaaaa-6700-0000-0000-000000000001');
select test.check('Délai à 0 : le Standard repassé compte',
  (select (m->>'avoided') || '|' || (m->>'avoided_tickets') || '|' || (m->>'double_scans')
     from (select public.event_dashboard(:'ev')->'money' as m) x),
  '14000|3|0');

-- Réglage depuis la console -----------------------------------------------------------
select test.expect_error('Promoteur : réglage refusé',
  'select public.admin_save_double_scan_seconds(30)', 'forbidden');
select test.login('aaaaaaaa-6700-0000-0000-000000000004');
select test.expect_error('Administrateur support : réglage refusé',
  'select public.admin_save_double_scan_seconds(30)', 'admin_role_forbidden');
select test.login('aaaaaaaa-6700-0000-0000-000000000003');
select test.expect_error('Délai hors limites',
  'select public.admin_save_double_scan_seconds(301)', 'double_scan_invalid');
select test.check('Super administrateur : délai à 30 s',
  public.admin_save_double_scan_seconds(30)->>'double_scan_seconds', '30');
select test.check('Délai relu par la console',
  public.admin_console_settings()->>'double_scan_seconds', '30');
reset role;
select test.check('Réglage journalisé sans motif personnel',
  (select count(*)::text from public.audit_logs
    where action = 'admin.double_scan_updated'
      and actor_id = 'aaaaaaaa-6700-0000-0000-000000000003'
      and details = '{"seconds": 30}'::jsonb),
  '1');
update private.console_settings s set value = '15'::jsonb where s.key = 'double_scan_seconds';

-- Contrôleur : pas de tableau de bord, donc pas de montants -------------------------
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-6700-0000-0000-000000000002', 'controller');
set role authenticated;
select test.login('aaaaaaaa-6700-0000-0000-000000000002');
select test.expect_error('Contrôleur : tableau de bord refusé',
  format('select public.event_dashboard(%L)', :'ev'), 'event_not_found');
reset role;
