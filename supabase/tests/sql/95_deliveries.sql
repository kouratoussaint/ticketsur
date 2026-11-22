-- =============================================================================
-- TicketSûr — Tests : journal des envois de tickets (migration 1500)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1500-0000-0000-000000000001', 'proprio-envoi@test.local'),
  ('aaaaaaaa-1500-0000-0000-000000000002', 'controle-envoi@test.local'),
  ('aaaaaaaa-1500-0000-0000-000000000003', 'autre-envoi@test.local');

set role authenticated;
select test.login('aaaaaaaa-1500-0000-0000-000000000001');
select (public.create_organization('Envoi Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert envoi', now() + interval '1 hour',
                            now() + interval '5 hours')).id as evt \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as cat \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_

create temp table sent as
select * from public.issue_named_tickets(:'evt', jsonb_build_array(
  jsonb_build_object('category_id', :'cat', 'name', 'Awa', 'phone', '70112233'),
  jsonb_build_object('category_id', :'cat', 'name', 'Issa', 'email', 'issa@exemple.bf'),
  jsonb_build_object('category_id', :'cat', 'name', 'Moussa')
));
select ticket_id as t1 from sent where line = 1 \gset
select ticket_id as t2 from sent where line = 2 \gset
select ticket_id as t3 from sent where line = 3 \gset

select test.check('Avant tout envoi : 3 tickets jamais envoyés',
  (select count(*) || '/' || bool_and(last_delivery_at is null)
   from public.event_tickets(:'evt', p_undelivered => true)), '3/true');

select test.check('Envoi WhatsApp enregistré à l''heure du serveur',
  (public.record_ticket_delivery(:'t1', 'whatsapp') = now())::text, 'true');
select public.record_ticket_delivery(:'t2', 'sms') \gset ignored_
select public.record_ticket_delivery(:'t2', 'email') \gset ignored_

select test.check('Liste : dernier envoi par ticket',
  (select string_agg(holder_name || ':' || coalesce(last_delivery_channel::text, '-'), ','
                     order by holder_name)
   from public.event_tickets(:'evt')),
  'Awa:whatsapp,Issa:email,Moussa:-');
select test.check('Filtre « jamais envoyés »',
  (select string_agg(holder_name, ',') from public.event_tickets(:'evt', p_undelivered => true)),
  'Moussa');
-- Recherche par le nom complet du titulaire : la référence aléatoire d'un
-- autre ticket (« TS-XAWA-… ») ne peut pas contenir d'espace.
select test.check('Filtre combiné au statut et à la recherche',
  (select count(*) from public.event_tickets(:'evt', 'issued', 'awa', p_undelivered => true)
    where holder_name ilike '%awa%')::text,
  '0');
select test.check('Journal : aucune donnée personnelle (ni numéro, ni adresse)',
  (select count(*) from information_schema.columns
   where table_schema = 'public' and table_name = 'ticket_deliveries'
     and column_name not in ('id', 'ticket_id', 'channel', 'sent_by', 'sent_at'))::text, '0');
select test.check('Journal lisible par l''organisateur',
  (select count(*) from public.ticket_deliveries where ticket_id in (:'t1', :'t2'))::text, '3');

select test.expect_error('Canal inconnu',
  format($q$select public.record_ticket_delivery(%L, 'pigeon')$q$, :'t3'),
  'delivery_channel_invalid', 'Canal inconnu (whatsapp, sms ou email).');
select test.expect_error('Ticket inconnu',
  format($q$select public.record_ticket_delivery(%L, 'sms')$q$, gen_random_uuid()),
  'ticket_not_found');
select public.revoke_ticket(:'t3', 'Test') \gset ignored_
select test.expect_error('Ticket annulé : envoi refusé',
  format($q$select public.record_ticket_delivery(%L, 'sms')$q$, :'t3'),
  'ticket_not_sendable');

-- Écriture directe interdite (l'API passe par la fonction).
do $$
begin
  insert into public.ticket_deliveries (ticket_id, channel, sent_by)
  values ((select ticket_id from sent where line = 1), 'sms', auth.uid());
  raise exception 'ÉCHEC  insertion directe acceptée';
exception when insufficient_privilege then
  raise notice 'OK    Insertion directe dans le journal refusée';
end $$;

-- Droits ------------------------------------------------------------------------
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-1500-0000-0000-000000000002', 'controller');
set role authenticated;
select test.login('aaaaaaaa-1500-0000-0000-000000000002');
select test.expect_error('Contrôleur : envoi non enregistrable',
  format($q$select public.record_ticket_delivery(%L, 'sms')$q$, :'t1'),
  'ticket_not_found');
select test.check('Contrôleur : journal invisible (RLS)',
  (select count(*) from public.ticket_deliveries)::text, '0');

select test.login('aaaaaaaa-1500-0000-0000-000000000003');
select test.expect_error('Autre organisation : envoi non enregistrable',
  format($q$select public.record_ticket_delivery(%L, 'whatsapp')$q$, :'t1'),
  'ticket_not_found');

reset role;
drop table if exists sent;
