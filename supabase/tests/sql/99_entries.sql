-- =============================================================================
-- Tikéo — Tests : pass à plusieurs entrées (migration 3400)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3400-0000-0000-000000000001', 'promoteur-pass@test.local'),
  ('aaaaaaaa-3400-0000-0000-000000000002', 'controleur-pass@test.local');

set role authenticated;
select test.login('aaaaaaaa-3400-0000-0000-000000000001');
select (public.create_organization('Studio Pass Qpv')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Festival Pass Qpv', now() + interval '1 day',
                            now() + interval '4 days')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Unique')).id as single \gset
select (public.create_ticket_category(:'ev', 'Pass 3 jours')).id as daily \gset
select (public.create_ticket_category(:'ev', 'Pass 3 sessions')).id as limited \gset
select (public.create_checkpoint(:'ev', 'Entrée')).id as cp \gset
select test.complete_event(:'ev') \gset ignored_

-- Règle d'entrée ---------------------------------------------------------------
select set_config('test.limited', :'limited', false) \gset ignored_
do $$
begin
  begin
    perform public.set_category_entry_policy(current_setting('test.limited')::uuid, 'limited', 1);
    raise exception 'ÉCHEC  pass d''une seule entrée accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'category_entries_invalid' then raise; end if;
    raise notice 'OK    Pass limité : 2 entrées au moins';
  end;
  begin
    perform public.set_category_entry_policy(current_setting('test.limited')::uuid, 'weekly');
    raise exception 'ÉCHEC  règle inconnue acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Règle d''entrée inconnue refusée';
  end;
end $$;
select public.set_category_entry_policy(:'daily', 'per_day') \gset ignored_
select public.set_category_entry_policy(:'limited', 'limited', 3) \gset ignored_
select test.check('Catégories : règle et nombre d''entrées lus',
  (select string_agg(name || ':' || entry_policy || ':' || coalesce(max_entries::text, '-'), ','
                     order by name)
     from public.event_categories(:'ev')),
  'Pass 3 jours:per_day:-,Pass 3 sessions:limited:3,Unique:single:-');

select public.set_event_status(:'ev', 'published') \gset ignored_
select ticket_id as ts, qr_token as qs from public.issue_tickets(:'ev', :'single', 1) \gset
select ticket_id as td, qr_token as qd from public.issue_tickets(:'ev', :'daily', 1) \gset
select ticket_id as tl, qr_token as ql from public.issue_tickets(:'ev', :'limited', 1) \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-3400-0000-0000-000000000002', 'controller');
insert into public.event_assignments (event_id, user_id, checkpoint_id)
values (:'ev', 'aaaaaaaa-3400-0000-0000-000000000002', :'cp');
set role authenticated;
select test.login('aaaaaaaa-3400-0000-0000-000000000002');
do $$
begin
  begin
    perform public.set_category_entry_policy(current_setting('test.limited')::uuid, 'single');
    raise exception 'ÉCHEC  règle modifiée par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Règle d''entrée réservée aux gestionnaires';
  end;
end $$;
select test.login('aaaaaaaa-3400-0000-0000-000000000001');
select public.set_event_status(:'ev', 'in_progress') \gset ignored_

-- Scan : résultat, entrée n°, règle --------------------------------------------
select test.login('aaaaaaaa-3400-0000-0000-000000000002');
create temporary table pass_scans (label text, response jsonb);
grant all on pass_scans to authenticated;
insert into pass_scans
select 'single-1', public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'qs');
insert into pass_scans
select 'single-2', public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'qs');
insert into pass_scans
select 'daily-1', public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'qd');
insert into pass_scans
select 'daily-2', public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'qd');
select test.check('Entrée unique : comme avant, une seule fois',
  (select string_agg((response->>'result') || ':' || coalesce(response->>'entries', '-'), ','
                     order by label)
     from pass_scans where label like 'single%'),
  'accepted:-,already_used:-');
select test.check('Pass journalier : accepté, puis refusé le même jour',
  (select string_agg((response->>'result') || ':' || (response->'entries'->>'policy') || ':'
                     || (response->'entries'->>'used'), ',' order by label)
     from pass_scans where label like 'daily%'),
  'accepted:per_day:1,already_used:per_day:1');

-- Le lendemain (dernière entrée reculée d'un jour) : de nouveau accepté.
reset role;
update public.tickets set last_entry_at = last_entry_at - interval '1 day',
       first_entry_at = first_entry_at - interval '1 day' where id = :'td';
update public.scan_attempts set server_time = server_time - interval '1 day'
 where ticket_id = :'td';
set role authenticated;
select test.login('aaaaaaaa-3400-0000-0000-000000000002');
insert into pass_scans
select 'daily-3', public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'qd');
select test.check('Pass journalier : accepté le jour suivant, entrée n° 2',
  (select (response->>'result') || ':' || (response->'entries'->>'used')
     from pass_scans where label = 'daily-3'),
  'accepted:2');

-- Pass de 3 entrées : 3 acceptées, la 4e refusée.
insert into pass_scans
select 'limited-' || n, public.validate_scan(gen_random_uuid(), :'ev', :'cp', :'ql')
  from generate_series(1, 4) n;
select test.check('Pass de 3 entrées : 1, 2, 3, puis refusé',
  (select string_agg((response->>'result') || ':' || (response->'entries'->>'used') || '/'
                     || (response->'entries'->>'max'), ',' order by label)
     from pass_scans where label like 'limited%'),
  'accepted:1/3,accepted:2/3,accepted:3/3,already_used:3/3');
reset role;
select test.check('Pass épuisé : ticket utilisé ; journalier encore valable',
  (select string_agg((case when id = :'tl' then 'pass' else 'jour' end) || ':'
                     || status::text || ':' || entries_used, ',' order by entries_used)
     from public.tickets where id in (:'tl', :'td')),
  'jour:issued:2,pass:redeemed:3');
select test.check('Journal : un numéro d''entrée par tentative acceptée',
  (select string_agg(entry_number::text, ',' order by entry_number)
     from public.scan_attempts where ticket_id = :'tl' and outcome = 'accepted'),
  '1,2,3');

-- Invariant défensif : jamais deux acceptations pour la même entrée.
select set_config('test.tl', :'tl', false) \gset ignored_
do $$
begin
  begin
    insert into public.scan_attempts (ticket_id, actor_id, event_id, outcome, entry_number)
    select ticket_id, actor_id, event_id, 'accepted', 2
      from public.scan_attempts
     where ticket_id = current_setting('test.tl')::uuid
       and outcome = 'accepted' limit 1;
    raise exception 'ÉCHEC  deuxième acceptation de l''entrée n° 2';
  exception when unique_violation then
    raise notice 'OK    Une seule acceptation par entrée d''un ticket';
  end;
end $$;

-- Tableau de bord : personnes entrées et entrées -------------------------------
set role authenticated;
select test.login('aaaaaaaa-3400-0000-0000-000000000001');
select test.check('Tableau de bord : 3 tickets entrés, 6 entrées acceptées',
  (select (d->'tickets'->>'admitted') || '|' || (d->'scans'->>'accepted')
     from (select public.event_dashboard(:'ev')::jsonb as d) x),
  '3|6');
select test.check('Catégories : entrés au moins une fois',
  (select string_agg(name || ':' || redeemed, ',' order by name)
     from public.event_categories(:'ev')),
  'Pass 3 jours:1,Pass 3 sessions:1,Unique:1');

-- Règle figée après la première entrée ------------------------------------------
select set_config('test.daily', :'daily', false) \gset ignored_
do $$
begin
  begin
    perform public.set_category_entry_policy(current_setting('test.daily')::uuid, 'single');
    raise exception 'ÉCHEC  règle changée après des entrées';
  exception when object_not_in_prerequisite_state then
    if sqlerrm <> 'category_has_entries' then raise; end if;
    raise notice 'OK    Règle figée dès la première entrée';
  end;
end $$;

select test.check('Tableau de bord : émis = entrés + restants + expirés',
  (select (d->'tickets'->>'issued') || '=' || (d->'tickets'->>'admitted') || '+'
          || (d->'tickets'->>'remaining') || '+' || (d->'tickets'->>'expired')
     from (select public.event_dashboard(:'ev')::jsonb as d) x),
  '3=3+0+0');

-- Pass entré : titulaire figé ; pass annulé : plus compté parmi les entrés.
select set_config('test.td', :'td', false) \gset ignored_
do $$
begin
  begin
    perform public.set_ticket_holder(current_setting('test.td')::uuid, 'Awa Prêt');
    raise exception 'ÉCHEC  titulaire d''un pass entré modifié';
  exception when object_not_in_prerequisite_state then
    if sqlerrm <> 'ticket_not_editable' then raise; end if;
    raise notice 'OK    Pass déjà entré : titulaire figé';
  end;
end $$;
select public.revoke_ticket(:'td') \gset ignored_
select test.check('Pass annulé : ni émis ni entré',
  (select (d->'tickets'->>'issued') || '=' || (d->'tickets'->>'admitted') || '+'
          || (d->'tickets'->>'remaining') || '+' || (d->'tickets'->>'expired')
     from (select public.event_dashboard(:'ev')::jsonb as d) x),
  '2=2+0+0');

-- Duplication : règle recopiée ---------------------------------------------------
select public.duplicate_event(:'ev', 'Festival Pass Qpv bis', now() + interval '10 days',
                              now() + interval '12 days') as dup \gset
reset role;
select test.check('Duplication : règles d''entrée recopiées',
  (select string_agg(name || ':' || entry_policy || ':' || coalesce(max_entries::text, '-'), ','
                     order by name)
     from public.ticket_categories where event_id = :'dup'),
  'Pass 3 jours:per_day:-,Pass 3 sessions:limited:3,Unique:single:-');
drop table pass_scans;
