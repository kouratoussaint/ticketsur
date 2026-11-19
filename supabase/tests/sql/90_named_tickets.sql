-- =============================================================================
-- TicketSûr — Tests : tickets nominatifs (migration 1400)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-1400-0000-0000-000000000001', 'proprio-nom@test.local'),
  ('aaaaaaaa-1400-0000-0000-000000000002', 'controle-nom@test.local');

-- Vérifie qu'un appel échoue avec le code et le détail attendus, sans rien
-- émettre (nombre de tickets de l'événement inchangé).
create or replace function test.expect_error(
  p_label text, p_sql text, p_code text, p_detail text default null, p_event uuid default null
) returns text language plpgsql as $$
declare
  v_before integer;
  v_after integer;
  v_detail text;
begin
  if p_event is not null then
    select count(*) into v_before from public.tickets where event_id = p_event;
  end if;
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_detail = pg_exception_detail;
    if sqlerrm <> p_code then
      raise exception 'ÉCHEC  % : code « % » au lieu de « % »', p_label, sqlerrm, p_code;
    end if;
    if p_detail is not null and v_detail is distinct from p_detail then
      raise exception 'ÉCHEC  % : détail « % » au lieu de « % »', p_label, v_detail, p_detail;
    end if;
    if p_event is not null then
      select count(*) into v_after from public.tickets where event_id = p_event;
      if v_after <> v_before then
        raise exception 'ÉCHEC  % : % tickets émis malgré l''erreur', p_label, v_after - v_before;
      end if;
    end if;
    return 'OK    ' || p_label;
  end;
  raise exception 'ÉCHEC  % : aucune erreur', p_label;
end $$;
grant execute on function test.expect_error(text, text, text, text, uuid) to authenticated;

set role authenticated;
select test.login('aaaaaaaa-1400-0000-0000-000000000001');
select (public.create_organization('Nominatif Test')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Gala nominatif', now() + interval '1 hour',
                            now() + interval '5 hours', 'Africa/Ouagadougou',
                            null, 10)).id as evt \gset
select (public.create_ticket_category(:'evt', 'VIP', 3)).id as vip \gset
select (public.create_ticket_category(:'evt', 'Standard')).id as std \gset
select (public.create_event(:'org', 'Autre gala', now() + interval '1 day',
                            now() + interval '1 day 4 hours')).id as other_evt \gset
select (public.create_ticket_category(:'other_evt', 'Ailleurs')).id as other_cat \gset
select test.complete_event(:'evt') \gset ignored_
select public.set_event_status(:'evt', 'published') \gset ignored_

-- Émission nominative -----------------------------------------------------------
create temp table named as
select * from public.issue_named_tickets(:'evt', jsonb_build_array(
  jsonb_build_object('category_id', :'vip', 'name', '  Awa   Ouédraogo ',
                     'phone', '70 11 22 33', 'email', ' AWA@Exemple.BF '),
  jsonb_build_object('category_id', :'std', 'name', 'Issa', 'phone', '+225 07 08 09 10 11'),
  jsonb_build_object('category_id', :'std')
));
select test.check('Émission : 3 lignes dans l''ordre, catégories nommées',
  (select string_agg(line || ':' || category_name || ':' || coalesce(holder_name, '-'), ','
                     order by line) from named),
  '1:VIP:Awa Ouédraogo,2:Standard:Issa,3:Standard:-');
select test.check('Émission : jetons QR au format TS1, références distinctes',
  (select (bool_and(qr_token ~ '^TS1\.[A-Za-z0-9_-]{43}$')
           and count(distinct public_reference) = 3)::text from named), 'true');
select test.check('Titulaire normalisé (espaces, téléphone international, e-mail en minuscules)',
  (select t.holder_name || '|' || t.holder_phone || '|' || t.holder_email
   from public.tickets t join named n on n.ticket_id = t.id where n.line = 1),
  'Awa Ouédraogo|+22670112233|awa@exemple.bf');
select test.check('Ticket sans titulaire : champs vides',
  (select (t.holder_name is null and t.holder_phone is null and t.holder_email is null)::text
   from public.tickets t join named n on n.ticket_id = t.id where n.line = 3), 'true');

select ticket_id as t_awa from named where line = 1 \gset
select ticket_id as t_anon from named where line = 3 \gset

-- Journal sans donnée personnelle.
select test.check('Journal : une entrée par catégorie, nombre de nominatifs',
  (select string_agg((details->>'quantity') || '/' || (details->>'named'), ',' order by details->>'quantity')
   from public.audit_logs where action = 'tickets.issued' and details->>'event_id' = :'evt'),
  '1/1,2/1');
select test.check('Journal : aucun nom, téléphone ni e-mail',
  (select count(*) from public.audit_logs
   where details->>'event_id' = :'evt'
     and (details::text like '%Awa%' or details::text like '%2267011%'
          or details::text like '%exemple.bf%'))::text, '0');

-- Liste et recherche ------------------------------------------------------------
select test.check('Liste : titulaire renvoyé',
  (select holder_name || '|' || holder_phone from public.event_tickets(:'evt') where id = :'t_awa'),
  'Awa Ouédraogo|+22670112233');
select test.check('Recherche par nom (sans casse)',
  (select count(*) || ':' || max(public_reference)
   from public.event_tickets(:'evt', null, 'awa')),
  '1:' || (select public_reference from named where line = 1));
select test.check('Recherche par téléphone (chiffres, espaces ignorés)',
  (select count(*) from public.event_tickets(:'evt', null, '22 33'))::text, '1');
select test.check('Recherche par e-mail',
  (select count(*) from public.event_tickets(:'evt', null, 'EXEMPLE.BF'))::text, '1');

select test.check('Ré-export : titulaire avec le jeton',
  (select holder_name from public.export_tickets(array[:'t_awa']::uuid[])), 'Awa Ouédraogo');

-- Émission anonyme inchangée -------------------------------------------------------
create temp table anon as select * from public.issue_tickets(:'evt', :'std', 2);
select test.check('issue_tickets : contrat inchangé, sans titulaire',
  (select count(*) || ':' || bool_and(t.holder_name is null)
   from anon i join public.tickets t on t.id = i.ticket_id), '2:true');

-- Refus : tout ou rien -----------------------------------------------------------
select test.expect_error('Téléphone invalide : numéro de ligne, rien émis',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    jsonb_build_array(jsonb_build_object('category_id', :'std', 'name', 'Ok'),
                      jsonb_build_object('category_id', :'std', 'phone', '12'))),
  'holder_phone_invalid', 'Ligne 2 : numéro de téléphone invalide.', :'evt');
select test.expect_error('E-mail invalide',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    jsonb_build_array(jsonb_build_object('category_id', :'std', 'email', 'pas-un-mail'),
                      jsonb_build_object('category_id', :'std'))),
  'holder_email_invalid', 'Ligne 1 : adresse e-mail invalide.', :'evt');
select test.expect_error('Nom trop long',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    jsonb_build_array(jsonb_build_object('category_id', :'std', 'name', repeat('a', 121)))),
  'holder_name_invalid', 'nom de 120 caractères au plus.', :'evt');
select test.expect_error('Catégorie d''un autre événement',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    jsonb_build_array(jsonb_build_object('category_id', :'std'),
                      jsonb_build_object('category_id', :'other_cat'))),
  'category_not_found', null, :'evt');
select test.expect_error('Quota VIP dépassé : rien émis, même en Standard',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    jsonb_build_array(jsonb_build_object('category_id', :'std'),
                      jsonb_build_object('category_id', :'vip'),
                      jsonb_build_object('category_id', :'vip'),
                      jsonb_build_object('category_id', :'vip'))),
  'category_capacity_exceeded', 'Quota de la catégorie « VIP » dépassé (2 restants).', :'evt');
select test.expect_error('Capacité de l''événement dépassée (5 émis sur 10)',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    (select jsonb_agg(jsonb_build_object('category_id', :'std')) from generate_series(1, 6))),
  'event_capacity_exceeded', 'Capacité de l''événement dépassée (5 restants).', :'evt');
select test.expect_error('Aucune ligne',
  format($q$select * from public.issue_named_tickets(%L, '[]')$q$, :'evt'),
  'issue_rows_invalid', 'De 1 à 500 tickets par envoi.', :'evt');
select test.expect_error('Plus de 500 lignes',
  format($q$select * from public.issue_named_tickets(%L, %L)$q$, :'evt',
    (select jsonb_agg(jsonb_build_object('category_id', :'std')) from generate_series(1, 501))),
  'issue_rows_invalid', null, :'evt');

-- Titulaire d'un ticket existant -----------------------------------------------------
select test.check('Titulaire ajouté à un ticket anonyme, normalisé',
  (select holder_name || '|' || holder_phone || '|' || coalesce(holder_email, '-')
   from public.set_ticket_holder(:'t_anon', ' Moussa ', '76 00 00 00')),
  'Moussa|+22676000000|-');
select test.check('Titulaire lu dans la liste',
  (select holder_name from public.event_tickets(:'evt') where id = :'t_anon'), 'Moussa');
select test.check('Journal de modification : champs changés, jamais les valeurs',
  (select details::text from public.audit_logs
   where action = 'ticket.holder_updated' and resource_id = :'t_anon'),
  '{"name": true, "email": false, "phone": true}');
select test.check('Titulaire effacé',
  (select (holder_name is null and holder_phone is null)::text
   from public.set_ticket_holder(:'t_anon', '', null, null)), 'true');
select test.expect_error('Téléphone invalide à la modification',
  format($q$select * from public.set_ticket_holder(%L, 'X', 'abc')$q$, :'t_anon'),
  'holder_phone_invalid', 'numéro de téléphone invalide.');

select public.revoke_ticket(:'t_anon', 'Test') \gset ignored_
select test.expect_error('Ticket annulé : titulaire figé',
  format($q$select * from public.set_ticket_holder(%L, 'Y')$q$, :'t_anon'),
  'ticket_not_editable');

-- Droits ----------------------------------------------------------------------------
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-1400-0000-0000-000000000002', 'controller');
set role authenticated;
select test.login('aaaaaaaa-1400-0000-0000-000000000002');
do $$
begin
  perform * from public.issue_named_tickets(
    (select id from public.events where title = 'Gala nominatif'),
    '[{"category_id": null}]');
  raise exception 'ÉCHEC  contrôleur : émission acceptée';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : émission nominative refusée';
end $$;
select test.expect_error('Contrôleur : titulaire non modifiable',
  format($q$select * from public.set_ticket_holder(%L, 'Z')$q$, :'t_awa'),
  'ticket_not_found');
select test.check('Contrôleur : aucun titulaire lisible (RLS)',
  (select count(*) from public.tickets where holder_name is not null)::text, '0');

reset role;
drop table if exists named;
drop table if exists anon;
