-- =============================================================================
-- TicketSûr — Tests : gestion des événements (migration 0600, EVT-01/EVT-02)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('66666666-0000-0000-0000-000000000001', 'proprio-evt@test.local'),
  ('66666666-0000-0000-0000-000000000002', 'gestion-evt@test.local'),
  ('66666666-0000-0000-0000-000000000003', 'controle-evt@test.local'),
  ('66666666-0000-0000-0000-000000000004', 'etranger-evt@test.local');

set role authenticated;
select test.login('66666666-0000-0000-0000-000000000001');
select (public.create_organization('Festival Événements')::jsonb)->>'id' as org \gset
select test.login('66666666-0000-0000-0000-000000000004');
select (public.create_organization('Autre Maison')::jsonb)->>'id' as other_org \gset

reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', '66666666-0000-0000-0000-000000000002', 'manager'),
  (:'org', '66666666-0000-0000-0000-000000000003', 'controller');

set role authenticated;

-- ---------------------------------------------------------------- création
select test.login('66666666-0000-0000-0000-000000000002');
select (public.create_event(:'org', '  Concert   de clôture ',
          now() + interval '10 days', now() + interval '10 days 4 hours',
          'Africa/Abidjan', '  Stade du 4-Août ', 800)).id as evt \gset
select test.check('Gestionnaire : événement créé en brouillon',
  (select status::text from public.events where id = :'evt'), 'draft');
select test.check('Création : titre et lieu nettoyés',
  (select title || '|' || venue from public.events where id = :'evt'),
  'Concert de clôture|Stade du 4-Août');
select test.check('Création : fuseau conservé (EVT-02)',
  (select timezone from public.events where id = :'evt'), 'Africa/Abidjan');
select test.check('Création : fuseau par défaut Africa/Ouagadougou',
  (public.create_event(:'org', 'Défaut', now() + interval '1 day',
                       now() + interval '1 day 2 hours')).timezone, 'Africa/Ouagadougou');
select test.check('Gestionnaire : journal d''audit non lisible (propriétaire seul)',
  (select count(*) from public.audit_logs where resource_id = :'evt')::text, '0');
select test.login('66666666-0000-0000-0000-000000000001');
select test.check('Création : journal d''audit (lu par le propriétaire)',
  (select count(*) from public.audit_logs
   where resource_id = :'evt' and action = 'event.created')::text, '1');
select test.login('66666666-0000-0000-0000-000000000002');

do $$
declare
  v_org uuid := (select id from public.organizations where name = 'Festival Événements');
  v_cases text[][] := array[
    array['A', '1 day', '2 days', 'Africa/Ouagadougou', 'event_title_invalid'],
    array['Dates', '2 days', '1 day', 'Africa/Ouagadougou', 'event_dates_invalid'],
    array['Trop long', '1 day', '40 days', 'Africa/Ouagadougou', 'event_dates_invalid'],
    array['Fuseau', '1 day', '2 days', 'Afrique/Ouaga', 'event_timezone_invalid']
  ];
  v_case text[];
begin
  foreach v_case slice 1 in array v_cases loop
    begin
      perform public.create_event(v_org, v_case[1], now() + v_case[2]::interval,
                                  now() + v_case[3]::interval, v_case[4]);
      raise exception 'ÉCHEC  % accepté', v_case[5];
    exception when invalid_parameter_value then
      if sqlerrm <> v_case[5] then
        raise exception 'ÉCHEC  code % au lieu de %', sqlerrm, v_case[5];
      end if;
      raise notice 'OK    Refus % (22023)', v_case[5];
    end;
  end loop;
  begin
    perform public.create_event(v_org, 'Capacité', now() + interval '1 day',
                                now() + interval '2 days', 'Africa/Ouagadougou', null, 0);
    raise exception 'ÉCHEC  capacité 0 acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Refus event_capacity_invalid (22023)';
  end;
end $$;

-- Contrôleur et étranger : pas de création.
select test.login('66666666-0000-0000-0000-000000000003');
do $$
begin
  perform public.create_event((select id from public.organizations where name = 'Festival Événements'),
                              'Interdit', now() + interval '1 day', now() + interval '2 days');
  raise exception 'ÉCHEC  un contrôleur a créé un événement';
exception when insufficient_privilege then
  raise notice 'OK    Contrôleur : création refusée';
end $$;
select test.check('Contrôleur non affecté : ne voit pas l''événement',
  (select count(*) from public.events where id = :'evt')::text, '0');

select set_config('test.evt', :'evt', false) \gset ignored_
select test.login('66666666-0000-0000-0000-000000000004');
select test.check('Autre organisation : événement invisible (isolation)',
  (select count(*) from public.events where id = :'evt')::text, '0');
do $$
begin
  perform public.create_event((select id from public.organizations where name = 'Festival Événements'),
                              'Intrus', now() + interval '1 day', now() + interval '2 days');
  raise exception 'ÉCHEC  création dans une organisation étrangère';
exception when insufficient_privilege then
  raise notice 'OK    Organisation étrangère : création refusée';
end $$;
do $$
begin
  -- L'étranger connaît l'identifiant (fuite supposée) mais n'a aucun droit.
  perform public.set_event_status(current_setting('test.evt')::uuid, 'cancelled');
  raise exception 'ÉCHEC  statut changé par un étranger';
exception when insufficient_privilege then
  raise notice 'OK    Organisation étrangère : changement de statut refusé';
end $$;

-- Écriture directe interdite.
select test.login('66666666-0000-0000-0000-000000000001');
do $$
begin
  update public.events set title = 'Piraté' where organization_id is not null;
  raise exception 'ÉCHEC  écriture directe acceptée';
exception when insufficient_privilege then
  raise notice 'OK    Écriture directe sur events refusée (RPC obligatoire)';
end $$;

-- ---------------------------------------------------------------- édition
select test.check('Édition en brouillon',
  (public.update_event(:'evt', 'Concert final', now() + interval '11 days',
                       now() + interval '11 days 5 hours', 'Africa/Ouagadougou',
                       null, 1000)).title, 'Concert final');
select test.check('Édition : lieu effacé, capacité changée',
  (select coalesce(venue, '∅') || '|' || capacity from public.events where id = :'evt'), '∅|1000');

-- ---------------------------------------------------------------- transitions
select test.check('draft → published',
  (public.set_event_status(:'evt', 'published')).status::text, 'published');
select test.check('Édition encore permise une fois publié',
  (public.update_event(:'evt', 'Concert final', now() + interval '11 days',
                       now() + interval '11 days 5 hours', 'Africa/Ouagadougou')).status::text,
  'published');

reset role;
insert into public.ticket_categories (id, event_id, name, capacity)
values ('66666666-0000-0000-0000-0000000000c1', :'evt', 'Standard', 100);
set role authenticated;
select test.login('66666666-0000-0000-0000-000000000001');
select count(*) from public.issue_tickets(:'evt', '66666666-0000-0000-0000-0000000000c1', 3) \gset ignored_

do $$
declare v_evt uuid := (select id from public.events where title = 'Concert final');
begin
  begin
    perform public.set_event_status(v_evt, 'draft');
    raise exception 'ÉCHEC  retour en brouillon avec billets';
  exception when object_not_in_prerequisite_state then
    if sqlerrm <> 'event_has_tickets' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    published → draft refusé quand des billets existent';
  end;
  begin
    perform public.update_event(v_evt, 'Concert final', now() + interval '11 days',
                                now() + interval '11 days 5 hours', 'Africa/Ouagadougou', null, 2);
    raise exception 'ÉCHEC  capacité sous le nombre de billets émis';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_capacity_below_issued' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Capacité inférieure aux billets émis refusée';
  end;
  begin
    perform public.set_event_status(v_evt, 'archived');
    raise exception 'ÉCHEC  published → archived accepté';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    published → archived refusé (transition non prévue)';
  end;
end $$;

select test.check('published → in_progress',
  (public.set_event_status(:'evt', 'in_progress')).status::text, 'in_progress');
do $$
declare v_evt uuid := (select id from public.events where title = 'Concert final');
begin
  perform public.update_event(v_evt, 'Modifié', now() + interval '11 days',
                              now() + interval '11 days 5 hours', 'Africa/Ouagadougou');
  raise exception 'ÉCHEC  édition d''un événement en cours';
exception when object_not_in_prerequisite_state then
  raise notice 'OK    Édition refusée pendant l''événement (event_locked)';
end $$;
select test.check('in_progress → closed',
  (public.set_event_status(:'evt', 'closed')).status::text, 'closed');
do $$
declare v_evt uuid := (select id from public.events where title = 'Concert final');
begin
  perform public.set_event_status(v_evt, 'in_progress');
  raise exception 'ÉCHEC  réouverture d''un événement clôturé';
exception when object_not_in_prerequisite_state then
  raise notice 'OK    closed → in_progress refusé';
end $$;
select test.check('closed → archived',
  (public.set_event_status(:'evt', 'archived')).status::text, 'archived');
select test.check('Transitions journalisées (published, in_progress, closed, archived)',
  (select string_agg(details->>'to', ',' order by created_at, id) from public.audit_logs
   where resource_id = :'evt' and action = 'event.status_changed'),
  'published,in_progress,closed,archived');

-- Annulation d'un brouillon, puis archivage.
select (public.create_event(:'org', 'Annulé', now() + interval '3 days',
                            now() + interval '3 days 2 hours')).id as evt2 \gset
select test.check('draft → cancelled',
  (public.set_event_status(:'evt2', 'cancelled')).status::text, 'cancelled');
select test.check('cancelled → archived',
  (public.set_event_status(:'evt2', 'archived')).status::text, 'archived');

-- Publication d'un événement déjà terminé.
select (public.create_event(:'org', 'Passé', now() - interval '3 days',
                            now() - interval '2 days')).id as evt3 \gset
do $$
begin
  perform public.set_event_status((select id from public.events where title = 'Passé'), 'published');
  raise exception 'ÉCHEC  publication d''un événement terminé';
exception when object_not_in_prerequisite_state then
  if sqlerrm <> 'event_already_ended' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Publication d''un événement terminé refusée';
end $$;

-- Retour en brouillon possible tant qu'aucun billet n'existe.
select (public.create_event(:'org', 'Réversible', now() + interval '5 days',
                            now() + interval '5 days 3 hours')).id as evt4 \gset
select public.set_event_status(:'evt4', 'published') \gset ignored_
select test.check('published → draft sans billet',
  (public.set_event_status(:'evt4', 'draft')).status::text, 'draft');

reset role;
