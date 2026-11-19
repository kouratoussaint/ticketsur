-- =============================================================================
-- TicketSûr — Tests : catégories d'invitations (migration 1700)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1700-0000-0000-000000000001', 'proprio-invit@test.local');

set role authenticated;
select test.login('aaaaaaaa-1700-0000-0000-000000000001');
select (public.create_organization('Invitations Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala invitations', now() + interval '1 hour',
                            now() + interval '5 hours')).id as evt \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as std \gset
select (public.create_ticket_category(:'evt', 'Invités', 10, true)).id as inv \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_

select test.check('Catégorie : par défaut, pas une invitation',
  (select is_invitation::text from public.ticket_categories where id = :'std'), 'false');
select test.check('Catégorie : créée comme invitation',
  (select is_invitation::text from public.ticket_categories where id = :'inv'), 'true');

-- Ancienne APK : modification sans le nouveau paramètre → marque conservée.
select (public.update_ticket_category(:'inv', 'Invités VIP', 12)).is_invitation::text as kept \gset
select test.check('Modification sans le paramètre : invitation conservée', :'kept', 'true');
select (public.update_ticket_category(:'std', 'Standard', null, true)).is_invitation::text as on_ \gset
select (public.update_ticket_category(:'std', 'Standard', null, false)).is_invitation::text as off_ \gset
select test.check('Modification : marque posée puis retirée', :'on_' || '/' || :'off_', 'true/false');
select test.check('Création et modification journalisées avec la marque',
  (select string_agg(details->>'is_invitation', ',' order by id) from public.audit_logs
   where resource_id = :'inv'),
  'true,true');

select test.check('Liste des catégories : marque renvoyée',
  (select string_agg(name || ':' || is_invitation, ',' order by name)
   from public.event_categories(:'evt')),
  'Invités VIP:true,Standard:false');

create temp table inv_rows as
select * from public.issue_named_tickets(:'evt', jsonb_build_array(
  jsonb_build_object('category_id', :'inv', 'name', 'Awa'),
  jsonb_build_object('category_id', :'std', 'name', 'Zoé')
));
select ticket_id as t_awa from inv_rows where line = 1 \gset
select ticket_id as t_zoe from inv_rows where line = 2 \gset
select test.check('Émission nominative : invitation signalée',
  (select string_agg(holder_name || ':' || category_is_invitation, ',' order by line) from inv_rows),
  'Awa:true,Zoé:false');
select test.check('Export : invitation signalée',
  (select string_agg(holder_name || ':' || category_is_invitation, ',' order by holder_name)
   from public.export_tickets(array[:'t_awa', :'t_zoe']::uuid[])),
  'Awa:true,Zoé:false');
select test.check('Liste des tickets : invitation signalée',
  (select string_agg(holder_name || ':' || category_is_invitation, ',' order by holder_name)
   from public.event_tickets(:'evt')),
  'Awa:true,Zoé:false');
select test.check('Rapport : invitation signalée',
  (select string_agg(holder_name || ':' || category_is_invitation, ',' order by holder_name)
   from public.event_report_rows(:'evt')),
  'Awa:true,Zoé:false');
select test.check('Tableau de bord : invitations comptées à part',
  (select (d->'tickets'->>'issued') || '/' || (d->'tickets'->>'invitations') || '/'
          || (d->'tickets'->>'invitations_admitted') || '/'
          || (select string_agg(c->>'is_invitation', ',' order by c->>'name')
              from jsonb_array_elements(d->'categories') c)
   from public.event_dashboard(:'evt') d),
  '2/1/0/true,false');

reset role;
drop table if exists inv_rows;
