-- =============================================================================
-- TicketSûr — Tests : liste du rapport d'événement (migration 1600)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1600-0000-0000-000000000001', 'proprio-rapport@test.local'),
  ('aaaaaaaa-1600-0000-0000-000000000002', 'controle-rapport@test.local');

set role authenticated;
select test.login('aaaaaaaa-1600-0000-0000-000000000001');
select (public.create_organization('Rapport Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala rapport', now() + interval '1 hour',
                            now() + interval '5 hours')).id as evt \gset
select (public.create_ticket_category(:'evt', 'VIP')).id as vip \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as std \gset
select (public.create_checkpoint(:'evt', 'Porte A')).id as cp \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_

create temp table rep as
select * from public.issue_named_tickets(:'evt', jsonb_build_array(
  jsonb_build_object('category_id', :'std', 'name', 'Zoé', 'phone', '70112233'),
  jsonb_build_object('category_id', :'vip', 'name', 'Awa', 'email', 'awa@exemple.bf'),
  jsonb_build_object('category_id', :'std')
));
select ticket_id as t_awa, qr_token as tok_awa from rep where line = 2 \gset
select ticket_id as t_anon from rep where line = 3 \gset
select public.record_ticket_delivery(:'t_awa', 'email') \gset ignored_
select public.revoke_ticket(:'t_anon', 'Test') \gset ignored_

reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-1600-0000-0000-000000000002', 'controller');
set role authenticated;
select public.assign_member(:'evt', 'aaaaaaaa-1600-0000-0000-000000000002') \gset ignored_
select public.set_event_status(:'evt', 'in_progress') \gset ignored_
select test.login('aaaaaaaa-1600-0000-0000-000000000002');
select (public.validate_scan('00000000-0000-4000-8000-000000001601', :'evt', :'cp', :'tok_awa'))->>'result' as r \gset

select test.login('aaaaaaaa-1600-0000-0000-000000000001');
create temp table rows as select * from public.event_report_rows(:'evt');

select test.check('Rapport : toutes les lignes, par catégorie puis nom',
  (select string_agg(category_name || ':' || coalesce(holder_name, '-') || ':' || status, ','
                     order by category_name = 'Standard', holder_name nulls last)
   from rows),
  'VIP:Awa:redeemed,Standard:Zoé:issued,Standard:-:revoked');
select test.check('Rapport : entrée, porte et dernier envoi',
  (select redeemed_checkpoint_name || '|' || last_delivery_channel || '|'
          || (redeemed_at is not null)::text
   from rows where holder_name = 'Awa'),
  'Porte A|email|true');
select test.check('Rapport : coordonnées des titulaires',
  (select holder_phone from rows where holder_name = 'Zoé'), '+22670112233');
select test.check('Rapport : aucune colonne de jeton',
  (select count(*) from pg_catalog.pg_proc p, unnest(p.proargnames) n
   where p.proname = 'event_report_rows' and n like '%token%')::text, '0');
select test.check('Rapport : export journalisé (nombre de lignes, sans contenu)',
  (select details::text from public.audit_logs
   where action = 'event.report_exported' and resource_id = :'evt'),
  '{"rows": 3}');

select test.login('aaaaaaaa-1600-0000-0000-000000000002');
select test.expect_error('Contrôleur : rapport refusé',
  format($q$select * from public.event_report_rows(%L)$q$, :'evt'),
  'event_not_found');
select test.login(null);
select test.expect_error('Sans session : rapport refusé',
  format($q$select * from public.event_report_rows(%L)$q$, :'evt'),
  'event_not_found');

reset role;
drop table if exists rep;
drop table if exists rows;
