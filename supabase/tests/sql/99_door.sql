-- =============================================================================
-- Tikéo — Tests : retrouver un titulaire à la porte (migration 2900)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2900-0000-0000-000000000001', 'promoteur-porte@test.local'),
  ('aaaaaaaa-2900-0000-0000-000000000002', 'controleur-porte@test.local'),
  ('aaaaaaaa-2900-0000-0000-000000000003', 'curieux-porte@test.local');

set role authenticated;
select test.login('aaaaaaaa-2900-0000-0000-000000000001');
select (public.create_organization('Studio Porte Qxd')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala Porte Qxd', now() + interval '1 day',
                            now() + interval '1 day 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'VIP')).id as cat \gset
select (public.create_checkpoint(:'ev', 'Entrée')).id as cp \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select ticket_id as t1 from public.issue_named_tickets(:'ev', jsonb_build_array(
  jsonb_build_object('category_id', :'cat', 'name', 'Aïcha Ouédraogo', 'phone', '70 11 22 33')))
  where line = 1 \gset
select ticket_id as t2 from public.issue_named_tickets(:'ev', jsonb_build_array(
  jsonb_build_object('category_id', :'cat', 'name', 'Issa Sawadogo'))) where line = 1 \gset
select qr_token as q2 from public.export_tickets(array[:'t2']::uuid[]) \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-2900-0000-0000-000000000002', 'controller');
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev', 'aaaaaaaa-2900-0000-0000-000000000002', :'cp');
select set_config('test.ev', :'ev', false) \gset ignored_
select set_config('test.cp', :'cp', false) \gset ignored_
set role authenticated;

-- Contrôle pas encore ouvert : pas de recherche ---------------------------------
select test.login('aaaaaaaa-2900-0000-0000-000000000002');
do $$
begin
  begin
    perform public.door_lookup(current_setting('test.ev')::uuid,
                               current_setting('test.cp')::uuid, 'aicha');
    raise exception 'ÉCHEC  recherche avant l''ouverture du contrôle';
  exception when insufficient_privilege then
    raise notice 'OK    Recherche fermée tant que le contrôle n''est pas ouvert';
  end;
end $$;
select test.login('aaaaaaaa-2900-0000-0000-000000000001');
select public.set_event_status(:'ev', 'in_progress') \gset ignored_

-- Recherche par nom (sans accents), téléphone, référence -------------------------
select test.login('aaaaaaaa-2900-0000-0000-000000000002');
select test.check('Nom sans accents : trouvé, téléphone masqué',
  (select holder_name || '|' || phone_hint || '|' || status::text
     from public.door_lookup(:'ev', :'cp', 'aicha ouedraogo')),
  'Aïcha Ouédraogo|•• 33|issued');
select test.check('Téléphone (4 chiffres au moins) : trouvé',
  (select count(*)::text from public.door_lookup(:'ev', :'cp', '1122')), '1');
reset role;
select public_reference as ref2 from public.tickets where id = :'t2' \gset
set role authenticated;
select test.check('Référence : trouvée',
  (select holder_name from public.door_lookup(:'ev', :'cp', :'ref2')),
  'Issa Sawadogo');
do $$
begin
  begin
    perform public.door_lookup(current_setting('test.ev')::uuid,
                               current_setting('test.cp')::uuid, 'ab');
    raise exception 'ÉCHEC  recherche trop courte acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Recherche trop courte refusée';
  end;
end $$;

-- Un compte non affecté ne cherche pas -----------------------------------------
select test.login('aaaaaaaa-2900-0000-0000-000000000003');
do $$
begin
  begin
    perform public.door_lookup(current_setting('test.ev')::uuid,
                               current_setting('test.cp')::uuid, 'issa');
    raise exception 'ÉCHEC  recherche par un compte non affecté';
  exception when insufficient_privilege then
    raise notice 'OK    Recherche réservée aux contrôleurs de la porte';
  end;
end $$;
select test.check('Validation par un compte non affecté : refusée',
  (public.validate_ticket_at_door('00000000-0000-4000-8000-000000002901', :'ev', :'cp', :'t1'))->>'result',
  'unauthorized');

-- Validation manuelle : mêmes règles que le scan ----------------------------------
select test.login('aaaaaaaa-2900-0000-0000-000000000002');
select public.validate_ticket_at_door('00000000-0000-4000-8000-000000002902', :'ev', :'cp', :'t1') as v1 \gset
select test.check('Validation manuelle : acceptée, nom du titulaire renvoyé',
  (:'v1'::jsonb)->>'result' || '|' || ((:'v1'::jsonb)->'ticket'->>'holder_name'),
  'accepted|Aïcha Ouédraogo');
select test.check('Rejeu du même request_id : même réponse',
  (public.validate_ticket_at_door('00000000-0000-4000-8000-000000002902', :'ev', :'cp', :'t1'))->>'validation_id',
  (:'v1'::jsonb)->>'validation_id');
select test.check('Seconde validation : déjà utilisé',
  (public.validate_ticket_at_door('00000000-0000-4000-8000-000000002903', :'ev', :'cp', :'t1'))->>'result',
  'already_used');
select test.check('Ticket d''un autre événement : introuvable',
  (public.validate_ticket_at_door('00000000-0000-4000-8000-000000002904', :'ev', :'cp',
     '00000000-0000-4000-8000-0000000029ff'))->>'result',
  'not_found');
select test.check('Scan par QR : le nom du titulaire est aussi renvoyé',
  (public.validate_scan('00000000-0000-4000-8000-000000002905', :'ev', :'cp', :'q2'))->'ticket'->>'holder_name',
  'Issa Sawadogo');
reset role;
select test.check('Journal : validations manuelles, sans donnée personnelle',
  (select string_agg(details->>'result', ',' order by details->>'result')
     from public.audit_logs where action = 'scan.manual' and resource_id = :'t1'),
  'accepted,already_used');
select test.check('Recherches : seule l''heure est gardée',
  (select count(*)::text from public.door_lookups
    where actor_id = 'aaaaaaaa-2900-0000-0000-000000000002'), '3');

-- Journal de la structure ------------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-2900-0000-0000-000000000002');
do $$
begin
  begin
    perform public.organization_audit_logs(
      (select organization_id from public.events where id = current_setting('test.ev')::uuid));
    raise exception 'ÉCHEC  journal lu par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Journal réservé au propriétaire';
  end;
end $$;
select test.login('aaaaaaaa-2900-0000-0000-000000000001');
select test.check('Journal : validation manuelle avec le contrôleur et le ticket',
  (select count(*)::text from public.organization_audit_logs(:'org', array['scan.'])
    where action = 'scan.manual' and actor_name is not null
      and subject like '% · Gala Porte Qxd' and not details ? 'request_id'),
  '2');
select test.check('Journal : filtre par familles d''actions',
  (select bool_and(action like 'event.%' or action like 'category.%')::text
     from public.organization_audit_logs(:'org', array['event.', 'category.'])),
  'true');
reset role;
