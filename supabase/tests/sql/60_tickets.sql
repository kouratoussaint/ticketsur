-- =============================================================================
-- TicketSûr — Tests : liste des billets et ré-export audité (migration 0900)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('99999999-0000-0000-0000-000000000001', 'proprio-billets@test.local'),
  ('99999999-0000-0000-0000-000000000002', 'controle-billets@test.local'),
  ('99999999-0000-0000-0000-000000000003', 'autre-billets@test.local');

set role authenticated;
select test.login('99999999-0000-0000-0000-000000000003');
select (public.create_organization('Autre billetterie')::jsonb)->>'id' as other_org \gset
select (public.create_event(:'other_org', 'Ailleurs', now() + interval '1 hour',
                            now() + interval '4 hours')).id as other_evt \gset
select (public.create_ticket_category(:'other_evt', 'Standard')).id as other_cat \gset
select test.complete_event(:'other_evt') \gset ignored_
select public.set_event_status(:'other_evt', 'published') \gset ignored_
select ticket_id as foreign_ticket from public.issue_tickets(:'other_evt', :'other_cat', 1) \gset

select test.login('99999999-0000-0000-0000-000000000001');
select (public.create_organization('Billetterie Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert billets', now() + interval '1 hour',
                            now() + interval '5 hours')).id as evt \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as cat_std \gset
select (public.create_ticket_category(:'evt', 'VIP')).id as cat_vip \gset
select (public.create_checkpoint(:'evt', 'Entrée')).id as cp \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_
create temp table issued_tickets as
  select * from public.issue_tickets(:'evt', :'cat_std', 2)
  union all
  select * from public.issue_tickets(:'evt', :'cat_vip', 1);
select i.ticket_id as t_vip, i.public_reference as ref_vip, i.qr_token as tok_vip
  from issued_tickets i join public.tickets t on t.id = i.ticket_id
  where t.category_id = :'cat_vip' \gset
select i.ticket_id as t_a, i.qr_token as tok_a from issued_tickets i
  join public.tickets t on t.id = i.ticket_id
  where t.category_id = :'cat_std' order by i.public_reference limit 1 \gset
select i.ticket_id as t_b from issued_tickets i
  join public.tickets t on t.id = i.ticket_id
  where t.category_id = :'cat_std' order by i.public_reference offset 1 limit 1 \gset

-- ------------------------------------------------------------ liste
select test.check('Liste : 3 billets, total 3',
  (select count(*) || '/' || max(total_count) from public.event_tickets(:'evt')), '3/3');
select test.check('Liste : aucune colonne secrète',
  (select count(*) from pg_catalog.pg_proc p, unnest(p.proargnames) n
   where p.proname = 'event_tickets' and n like '%token%')::text, '0');
select test.check('Recherche par fragment de référence (minuscules)',
  (select public_reference from public.event_tickets(:'evt', null, lower(substr(:'ref_vip', 4, 6)))),
  :'ref_vip');
select test.check('Recherche par catégorie',
  (select count(*) from public.event_tickets(:'evt', null, 'vip'))::text, '1');
select test.check('Pagination : 2e page de 2 → 1 billet, total 3',
  (select count(*) || '/' || max(total_count) from public.event_tickets(:'evt', null, null, 2, 2)), '1/3');

-- Scan d'un billet (contrôle démarré) : statut et porte visibles dans la liste.
select public.set_event_status(:'evt', 'in_progress') \gset ignored_
select public.assign_member(:'evt', '99999999-0000-0000-0000-000000000001') \gset ignored_
select (public.validate_scan('00000000-0000-4000-8000-0000000009a1', :'evt', :'cp', :'tok_a'))->>'result' as scan \gset
select test.check('Billet scanné : « redeemed » à la porte « Entrée »',
  (select status || '@' || redeemed_checkpoint_name from public.event_tickets(:'evt', 'redeemed')),
  'redeemed@Entrée');
select public.revoke_ticket(:'t_b', 'Erreur de saisie') \gset ignored_
select test.check('Filtre par statut : 1 annulé',
  (select count(*) from public.event_tickets(:'evt', 'revoked'))::text, '1');

-- ------------------------------------------------------------ ré-export
create temp table exported as
  select * from public.export_tickets(array[:'t_vip', :'t_a', :'t_b']::uuid[]);
select test.check('Ré-export : billet annulé exclu (2 sur 3)',
  (select count(*) from exported)::text, '2');
select test.check('Ré-export : jeton identique à celui de l''émission',
  (select qr_token from exported where ticket_id = :'t_vip'), :'tok_vip');
select test.check('Ré-export d''un billet déjà utilisé : permis, statut indiqué',
  (select status::text from exported where ticket_id = :'t_a'), 'redeemed');
select test.check('Ré-export journalisé (nombre de billets demandés)',
  (select (details->>'count') from public.audit_logs
   where action = 'tickets.exported' and resource_id = :'evt'), '3');
select test.check('Journal du ré-export : aucun jeton',
  (select count(*) from public.audit_logs
   where action = 'tickets.exported' and details::text like '%TS1.%')::text, '0');

do $$
begin
  begin
    perform * from public.export_tickets(array[]::uuid[]);
    raise exception 'ÉCHEC  export vide accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Export vide refusé';
  end;
  begin
    perform * from public.export_tickets(
      array(select gen_random_uuid() from generate_series(1, 201)));
    raise exception 'ÉCHEC  export de 201 billets accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Export limité à 200 billets par appel';
  end;
end $$;

select set_config('test.t_vip', :'t_vip', false) \gset ignored_
select set_config('test.foreign', :'foreign_ticket', false) \gset ignored_
do $$
begin
  perform * from public.export_tickets(array[current_setting('test.t_vip')::uuid,
                                             current_setting('test.foreign')::uuid]);
  raise exception 'ÉCHEC  billet d''une autre organisation exporté';
exception when insufficient_privilege then
  raise notice 'OK    Liste mêlant un billet étranger : export entier refusé';
end $$;

-- Contrôleur et étranger : ni liste ni export.
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', '99999999-0000-0000-0000-000000000002', 'controller');
set role authenticated;
select test.login('99999999-0000-0000-0000-000000000002');
do $$
begin
  begin
    perform * from public.export_tickets(array[current_setting('test.t_vip')::uuid]);
    raise exception 'ÉCHEC  export par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Contrôleur : ré-export refusé';
  end;
end $$;
select test.login('99999999-0000-0000-0000-000000000003');
do $$
begin
  perform * from public.event_tickets(
    (select t.event_id from public.tickets t where t.id = current_setting('test.foreign')::uuid));
  perform * from public.event_tickets(gen_random_uuid());
  raise exception 'ÉCHEC  liste d''un événement inconnu';
exception when insufficient_privilege then
  raise notice 'OK    Événement d''une autre organisation : liste refusée';
end $$;

reset role;
drop table if exists issued_tickets;
drop table if exists exported;
