-- =============================================================================
-- TicketSûr — Tests : catégories et portes (migration 0700, EVT-03, EVT-04)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('77777777-0000-0000-0000-000000000001', 'proprio-cat@test.local'),
  ('77777777-0000-0000-0000-000000000002', 'gestion-cat@test.local'),
  ('77777777-0000-0000-0000-000000000003', 'controle-cat@test.local'),
  ('77777777-0000-0000-0000-000000000004', 'etranger-cat@test.local');

set role authenticated;
select test.login('77777777-0000-0000-0000-000000000001');
select (public.create_organization('Maison des Quotas')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Festival quotas', now() + interval '1 hour',
                            now() + interval '7 hours', 'Africa/Ouagadougou',
                            null, 5)).id as evt \gset
select set_config('test.evt', :'evt', false) \gset ignored_

reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', '77777777-0000-0000-0000-000000000002', 'manager'),
  (:'org', '77777777-0000-0000-0000-000000000003', 'controller');
set role authenticated;

-- ------------------------------------------------------------- catégories
select test.login('77777777-0000-0000-0000-000000000002');
select (public.create_ticket_category(:'evt', '  Standard  ')).id as cat_std \gset
select (public.create_ticket_category(:'evt', 'VIP', 2)).id as cat_vip \gset
select set_config('test.cat_vip', :'cat_vip', false) \gset ignored_
select test.check('Gestionnaire : deux catégories créées, nom nettoyé',
  (select string_agg(name || ':' || coalesce(capacity::text, '∞'), ',' order by name)
   from public.ticket_categories where event_id = :'evt'), 'Standard:∞,VIP:2');

do $$
declare v_evt uuid := current_setting('test.evt')::uuid;
begin
  begin
    perform public.create_ticket_category(v_evt, 'vip');
    raise exception 'ÉCHEC  nom en double (casse différente) accepté';
  exception when unique_violation then
    if sqlerrm <> 'category_name_taken' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Nom de catégorie en double refusé (insensible à la casse)';
  end;
  begin
    perform public.create_ticket_category(v_evt, '   ');
    raise exception 'ÉCHEC  nom vide accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Nom de catégorie vide refusé';
  end;
  begin
    perform public.create_ticket_category(v_evt, 'Zéro', 0);
    raise exception 'ÉCHEC  quota 0 accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Quota 0 refusé';
  end;
end $$;

-- Émission impossible en brouillon.
select test.login('77777777-0000-0000-0000-000000000001');
do $$
begin
  perform public.issue_tickets(current_setting('test.evt')::uuid,
                               current_setting('test.cat_vip')::uuid, 1);
  raise exception 'ÉCHEC  émission dans un brouillon';
exception when object_not_in_prerequisite_state then
  if sqlerrm <> 'event_not_published' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Émission refusée tant que l''événement est en brouillon';
end $$;

select public.set_event_status(:'evt', 'published') \gset ignored_
create temp table cat_vip_tickets as
  select * from public.issue_tickets(:'evt', :'cat_vip', 2);
select test.check('Émission : 2 billets VIP', (select count(*) from cat_vip_tickets)::text, '2');
select qr_token as vip_token from cat_vip_tickets limit 1 \gset
select test.check('Émission : 3 billets Standard',
  (select count(*) from public.issue_tickets(:'evt', :'cat_std', 3))::text, '3');

do $$
begin
  perform public.issue_tickets(current_setting('test.evt')::uuid,
    (select id from public.ticket_categories where name = 'Standard'
       and event_id = current_setting('test.evt')::uuid), 1);
  raise exception 'ÉCHEC  capacité de l''événement dépassée';
exception when invalid_parameter_value then
  if sqlerrm <> 'event_capacity_exceeded' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    EVT-03 capacité de l''événement (5) respectée toutes catégories confondues';
end $$;

select test.check('Compteurs par catégorie (émis/consommés)',
  (select string_agg(name || ':' || issued || '/' || redeemed, ',' order by name)
   from public.event_categories(:'evt')), 'Standard:3/0,VIP:2/0');

do $$
declare v_vip uuid := current_setting('test.cat_vip')::uuid;
begin
  begin
    perform public.update_ticket_category(v_vip, 'VIP', 1);
    raise exception 'ÉCHEC  quota sous le nombre de billets émis';
  exception when invalid_parameter_value then
    if sqlerrm <> 'category_capacity_below_issued' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Quota inférieur aux billets émis refusé';
  end;
  begin
    perform public.delete_ticket_category(v_vip);
    raise exception 'ÉCHEC  suppression d''une catégorie avec billets';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Suppression refusée : des billets existent';
  end;
end $$;

select test.check('Renommer et élargir une catégorie',
  (select name || ':' || capacity from public.update_ticket_category(:'cat_vip', 'Carré VIP', 10)),
  'Carré VIP:10');
select (public.create_ticket_category(:'evt', 'Invitation')).id as cat_inv \gset
select public.delete_ticket_category(:'cat_inv') \gset ignored_
select test.check('Catégorie sans billet supprimée',
  (select count(*) from public.ticket_categories where id = :'cat_inv')::text, '0');

-- ----------------------------------------------------------------- portes
select (public.create_checkpoint(:'evt', 'Entrée Nord')).id as cp_nord \gset
select (public.create_checkpoint(:'evt', 'Entrée Sud')).id as cp_sud \gset
do $$
begin
  perform public.create_checkpoint(current_setting('test.evt')::uuid, 'entrée nord');
  raise exception 'ÉCHEC  porte en double acceptée';
exception when unique_violation then
  raise notice 'OK    Nom de porte en double refusé';
end $$;
select test.check('Porte renommée et désactivée',
  (select name || ':' || active from public.update_checkpoint(:'cp_sud', 'Entrée Sud (VIP)', false)),
  'Entrée Sud (VIP):false');

-- Une porte désactivée refuse les scans (validate_scan exige cp.active).
reset role;
insert into public.event_assignments (event_id, user_id)
values (:'evt', '77777777-0000-0000-0000-000000000003');
set role authenticated;
select test.login('77777777-0000-0000-0000-000000000001');
select public.set_event_status(:'evt', 'in_progress') \gset ignored_
select test.login('77777777-0000-0000-0000-000000000003');
select test.check('Porte désactivée : scan refusé (unauthorized)',
  (public.validate_scan('00000000-0000-4000-8000-0000000007a1', :'evt', :'cp_sud', :'vip_token'))->>'result',
  'unauthorized');
select test.check('Porte active : même billet accepté',
  (public.validate_scan('00000000-0000-4000-8000-0000000007a2', :'evt', :'cp_nord', :'vip_token'))->>'result',
  'accepted');

-- Contrôleur : pas de compteurs, pas d'écriture.
do $$
begin
  perform * from public.event_categories(current_setting('test.evt')::uuid);
  raise exception 'ÉCHEC  compteurs lus par un contrôleur';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : compteurs de billets refusés';
end $$;
do $$
begin
  perform public.create_checkpoint(current_setting('test.evt')::uuid, 'Porte pirate');
  raise exception 'ÉCHEC  porte créée par un contrôleur';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : création de porte refusée';
end $$;
select test.check('Contrôleur affecté : voit les portes (sélection de porte, S21)',
  (select count(*) from public.checkpoints where event_id = :'evt')::text, '2');

select test.login('77777777-0000-0000-0000-000000000001');
select test.check('Compteurs après scan (Carré VIP : 2 émis, 1 consommé)',
  (select issued || '/' || redeemed from public.event_categories(:'evt') where name = 'Carré VIP'),
  '2/1');

-- Organisation étrangère : rien.
select test.login('77777777-0000-0000-0000-000000000004');
do $$
declare v_evt uuid := current_setting('test.evt')::uuid;
begin
  begin
    perform public.create_ticket_category(v_evt, 'Intrus');
    raise exception 'ÉCHEC  catégorie créée par un étranger';
  exception when insufficient_privilege then
    raise notice 'OK    Étranger : création de catégorie refusée';
  end;
  begin
    perform public.update_ticket_category(current_setting('test.cat_vip')::uuid, 'Volée', null);
    raise exception 'ÉCHEC  catégorie modifiée par un étranger';
  exception when insufficient_privilege then
    raise notice 'OK    Étranger : modification de catégorie refusée';
  end;
  begin
    perform * from public.event_categories(v_evt);
    raise exception 'ÉCHEC  compteurs lus par un étranger';
  exception when insufficient_privilege then
    raise notice 'OK    Étranger : compteurs refusés';
  end;
end $$;
select test.check('Étranger : aucune porte ni catégorie visible',
  ((select count(*) from public.checkpoints where event_id = :'evt')
   + (select count(*) from public.ticket_categories where event_id = :'evt'))::text, '0');

-- Événement clôturé : structure figée.
select test.login('77777777-0000-0000-0000-000000000001');
select public.set_event_status(:'evt', 'closed') \gset ignored_
do $$
begin
  perform public.create_checkpoint(current_setting('test.evt')::uuid, 'Trop tard');
  raise exception 'ÉCHEC  porte ajoutée à un événement clôturé';
exception when object_not_in_prerequisite_state then
  raise notice 'OK    Événement clôturé : portes et catégories figées';
end $$;

reset role;
drop table if exists cat_vip_tickets;
