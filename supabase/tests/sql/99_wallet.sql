-- =============================================================================
-- Tikéo — Tests : « Mes tickets » (migration 2700)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2700-0000-0000-000000000001', 'promoteur-wallet@test.local'),
  ('aaaaaaaa-2700-0000-0000-000000000002', 'spectateur-wallet@test.local'),
  ('aaaaaaaa-2700-0000-0000-000000000003', 'voisin-wallet@test.local');

set role authenticated;
select test.login('aaaaaaaa-2700-0000-0000-000000000001');
select (public.create_organization('Studio Wallet Qxy')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Wallet Qxy', now() + interval '3 days',
                            now() + interval '3 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Fosse')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select ticket_id as t1, qr_token as q1 from public.issue_tickets(:'ev', :'cat', 1) \gset
select ticket_id as t2, qr_token as q2 from public.issue_tickets(:'ev', :'cat', 1) \gset
select public.revoke_ticket(:'t2', 'test') \gset ignored_
select set_config('test.q1', :'q1', false) \gset ignored_
select set_config('test.q2', :'q2', false) \gset ignored_

-- Le spectateur ajoute son ticket par le QR ------------------------------------
select test.login('aaaaaaaa-2700-0000-0000-000000000002');
select public.claim_ticket(:'q1') as claimed \gset
select test.check('QR reconnu : ticket ajouté', :'claimed', :'t1');
select test.check('Ajouter deux fois : sans effet', public.claim_ticket(:'q1')::text, :'t1');
select test.check('Mes tickets : le ticket, son événement, son QR',
  (select public_reference is not null and event_title = 'Concert Wallet Qxy'
          and organization_name = 'Studio Wallet Qxy' and qr_token = :'q1'
     from public.my_tickets() where ticket_id = :'t1')::text,
  'true');
select test.check('Mes tickets : structure et événement au catalogue (migration 5600)',
  (select (organization_id = :'org')::text || '|' || event_listed::text
     from public.my_tickets() where ticket_id = :'t1'),
  'true|true');
do $$
begin
  begin
    perform public.claim_ticket('TS1.pasunvraijeton');
    raise exception 'ÉCHEC  code mal formé accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Code mal formé refusé';
  end;
  begin
    perform public.claim_ticket('TS1.' || repeat('Z', 43));
    raise exception 'ÉCHEC  ticket inconnu accepté';
  exception when no_data_found then
    raise notice 'OK    Ticket inconnu refusé';
  end;
  begin
    perform public.claim_ticket(current_setting('test.q2'));
    raise exception 'ÉCHEC  ticket annulé ajouté';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Ticket annulé refusé';
  end;
end $$;

-- Un autre compte ne peut ni l'ajouter ni le voir ----------------------------
select test.login('aaaaaaaa-2700-0000-0000-000000000003');
do $$
begin
  begin
    perform public.claim_ticket(current_setting('test.q1'));
    raise exception 'ÉCHEC  ticket pris par un second compte';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Ticket déjà dans un autre compte : refusé';
  end;
end $$;
select test.check('Autre compte : aucun ticket',
  (select count(*)::text from public.my_tickets()), '0');
do $$
begin
  begin
    perform public.release_ticket(
      (select id from public.tickets where public_reference is not null
         and holder_user_id = 'aaaaaaaa-2700-0000-0000-000000000002' limit 1));
    raise exception 'ÉCHEC  ticket retiré par un autre compte';
  exception when no_data_found then
    raise notice 'OK    Retrait réservé au détenteur';
  end;
end $$;

-- Sans compte : rien -------------------------------------------------------------
set role anon;
do $$
begin
  begin
    perform public.my_tickets();
    raise exception 'ÉCHEC  tickets lus sans compte';
  exception when insufficient_privilege then
    raise notice 'OK    Sans compte : aucun accès';
  end;
end $$;
set role authenticated;

-- Utilisé : plus de QR renvoyé ; retiré : réajoutable ---------------------------
reset role;
update public.tickets set status = 'redeemed', redeemed_at = now(),
       redeemed_by = 'aaaaaaaa-2700-0000-0000-000000000001'
 where id = :'t1';
set role authenticated;
select test.login('aaaaaaaa-2700-0000-0000-000000000002');
select test.check('Ticket utilisé : statut, sans QR',
  (select status::text || '|' || coalesce(qr_token, '∅') from public.my_tickets()
    where ticket_id = :'t1'),
  'redeemed|∅');
select public.release_ticket(:'t1') \gset ignored_
select test.check('Retiré : plus dans Mes tickets',
  (select count(*)::text from public.my_tickets()), '0');
select test.login('aaaaaaaa-2700-0000-0000-000000000003');
select test.check('Retiré : un autre compte peut l''ajouter',
  public.claim_ticket(:'q1')::text, :'t1');
reset role;
select test.check('Journal : ajouts et retrait, sans donnée',
  (select string_agg(action || ':' || details::text, ',' order by action)
     from public.audit_logs where resource_id = :'t1'
      and action in ('ticket.claimed', 'ticket.released')),
  'ticket.claimed:{},ticket.claimed:{},ticket.released:{}');
