-- =============================================================================
-- Tikéo — Tests : lots de génération des tickets (migration 4500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-4500-0000-0000-000000000001', 'proprio-lots@test.local'),
  ('aaaaaaaa-4500-0000-0000-000000000002', 'controle-lots@test.local'),
  ('aaaaaaaa-4500-0000-0000-000000000003', 'autre-lots@test.local');

set role authenticated;
select test.login('aaaaaaaa-4500-0000-0000-000000000001');
select (public.create_organization('Studio Lots Xkv')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala des lots Xkv', now() + interval '4 days',
                            now() + interval '4 days 5 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as std \gset
select (public.create_ticket_category(:'ev', 'VIP')).id as vip \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_

-- Lot 1 : 3 tickets rapides ; lot 2 : 2 nominatifs (2 catégories).
select count(*) from public.issue_tickets(:'ev', :'std', 3) \gset ignored_
create temp table named as select * from public.issue_named_tickets(:'ev', jsonb_build_array(
  jsonb_build_object('category_id', :'vip', 'name', 'Aïcha Lots'),
  jsonb_build_object('category_id', :'std', 'name', 'Issa Lots')));

select test.check('Deux lots, du plus récent au plus ancien, avec leurs compteurs',
  (select string_agg(b.number || ':' || b.total || ':' || b.issued || ':' || b.named || ':'
                     || array_to_string(b.categories, '+'), ',' order by b.number desc)
     from public.event_ticket_batches(:'ev') b),
  '2:2:2:2:Standard+VIP,1:3:3:0:Standard');
select id as batch2 from public.event_ticket_batches(:'ev') where number = 2 \gset
select id as batch1 from public.event_ticket_batches(:'ev') where number = 1 \gset

select test.check('Tickets d''un lot : tous, dans l''ordre d''émission',
  (select count(*)::text from public.batch_ticket_ids(:'batch2')), '2');
select test.check('Liste filtrée par lot, avec le numéro du lot',
  (select string_agg(distinct t.batch_number::text, ',')
     || ':' || count(*)
     from public.event_tickets(:'ev', p_batch_id => :'batch1') t),
  '1:3');
select test.check('Liste complète : le numéro du lot sur chaque ticket',
  (select count(*)::text from public.event_tickets(:'ev') t where t.batch_number is not null),
  '5');

-- Annulation : compteur du lot mis à jour.
select public.revoke_tickets(array(select id from public.batch_ticket_ids(:'batch1') limit 1))
  \gset ignored_
select test.check('Ticket annulé compté dans son lot',
  (select b.issued || ':' || b.revoked from public.event_ticket_batches(:'ev') b
    where b.number = 1),
  '2:1');

-- Journal : le numéro du lot, aucun nom.
reset role;
select test.check('Journal : numéro du lot, sans nom ni téléphone',
  (select string_agg(distinct (a.details->>'batch'), ',' order by (a.details->>'batch'))
     from public.audit_logs a
    where a.action = 'tickets.issued' and a.details->>'event_id' = :'ev'
      and a.details::text not like '%Lots%'),
  '1,2');
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'aaaaaaaa-4500-0000-0000-000000000002', 'controller');
set role authenticated;

select test.login('aaaaaaaa-4500-0000-0000-000000000002');
select test.expect_error('Contrôleur : lots refusés',
  format($q$select * from public.event_ticket_batches(%L)$q$, :'ev'), 'event_not_found');
select test.expect_error('Contrôleur : tickets d''un lot refusés',
  format($q$select * from public.batch_ticket_ids(%L)$q$, :'batch1'), 'batch_not_found');
select test.login('aaaaaaaa-4500-0000-0000-000000000003');
select test.expect_error('Autre compte : lot inconnu',
  format($q$select * from public.batch_ticket_ids(%L)$q$, :'batch2'), 'batch_not_found');

reset role;
select test.check('Lots fermés à l''API',
  (has_table_privilege('authenticated', 'public.ticket_batches', 'select'))::text, 'false');
