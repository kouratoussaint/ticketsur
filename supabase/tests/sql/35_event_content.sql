-- =============================================================================
-- TicketSûr — Tests : contenu des événements et photo (migration 1100)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('cccccccc-0000-0000-0000-000000000001', 'proprio-contenu@test.local'),
  ('cccccccc-0000-0000-0000-000000000002', 'gestion-contenu@test.local'),
  ('cccccccc-0000-0000-0000-000000000003', 'controle-contenu@test.local'),
  ('cccccccc-0000-0000-0000-000000000004', 'etranger-contenu@test.local');

set role authenticated;
select test.login('cccccccc-0000-0000-0000-000000000001');
select (public.create_organization('Maison du Contenu')::jsonb)->>'id' as org \gset
select test.login('cccccccc-0000-0000-0000-000000000004');
select (public.create_organization('Maison Voisine')::jsonb)->>'id' as other_org \gset

reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'cccccccc-0000-0000-0000-000000000002', 'manager'),
  (:'org', 'cccccccc-0000-0000-0000-000000000003', 'controller');
set role authenticated;

-- ---------------------------------------------------------------- création
select test.login('cccccccc-0000-0000-0000-000000000002');
select (public.create_event(:'org', 'Festival des Masques',
          now() + interval '20 days', now() + interval '20 days 6 hours',
          'Africa/Ouagadougou', 'Place de la Nation', 2000,
          p_city => '  Bobo-Dioulasso ', p_country_code => 'bf',
          p_venue_address => ' Avenue  de la Révolution ',
          p_latitude => 11.1771, p_longitude => -4.2979,
          p_description => e'  Trois jours de danses.\r\n\r\n\r\n\r\nEntrée sur présentation du ticket.  ',
          p_kind => 'concert')).id as evt \gset

select test.check('Création : ville nettoyée',
  (select city from public.events where id = :'evt'), 'Bobo-Dioulasso');
select test.check('Création : code pays mis en majuscules',
  (select country_code from public.events where id = :'evt'), 'BF');
select test.check('Création : adresse nettoyée',
  (select venue_address from public.events where id = :'evt'), 'Avenue de la Révolution');
select test.check('Création : description, lignes conservées, vides réduits',
  (select description from public.events where id = :'evt'),
  e'Trois jours de danses.\n\nEntrée sur présentation du ticket.');
select test.check('Création : type et position',
  (select kind || '|' || latitude || '|' || longitude from public.events where id = :'evt'),
  'concert|11.1771|-4.2979');
select test.check('Création : sans photo au départ',
  (select coalesce(cover_path, '∅') from public.events where id = :'evt'), '∅');
select test.check('Création minimale : type « other », pays BF, ville vide',
  (select kind || '|' || country_code || '|' || coalesce(city, '∅')
   from public.create_event(:'org', 'Minimal', now() + interval '3 days',
                            now() + interval '3 days 2 hours')), 'other|BF|∅');

do $$
declare
  v_org uuid := (select id from public.organizations where name = 'Maison du Contenu');
begin
  begin
    perform public.create_event(v_org, 'Ville courte', now() + interval '1 day',
                                now() + interval '2 days', p_city => 'O');
    raise exception 'ÉCHEC  ville d''un caractère acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_city_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus event_city_invalid';
  end;
  begin
    perform public.create_event(v_org, 'Pays', now() + interval '1 day',
                                now() + interval '2 days', p_country_code => 'B1');
    raise exception 'ÉCHEC  code pays invalide accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_country_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus event_country_invalid';
  end;
  begin
    perform public.create_event(v_org, 'Position', now() + interval '1 day',
                                now() + interval '2 days', p_latitude => 12.3);
    raise exception 'ÉCHEC  position incomplète acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_location_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus event_location_invalid (latitude sans longitude)';
  end;
  begin
    perform public.create_event(v_org, 'Position', now() + interval '1 day',
                                now() + interval '2 days', p_latitude => 95, p_longitude => 1);
    raise exception 'ÉCHEC  latitude hors limites acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Refus event_location_invalid (latitude 95)';
  end;
  begin
    perform public.create_event(v_org, 'Description', now() + interval '1 day',
                                now() + interval '2 days', p_description => repeat('a', 2001));
    raise exception 'ÉCHEC  description trop longue acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_description_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus event_description_invalid';
  end;
  begin
    perform public.create_event(v_org, 'Adresse', now() + interval '1 day',
                                now() + interval '2 days', p_venue_address => repeat('a', 201));
    raise exception 'ÉCHEC  adresse trop longue acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_address_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus event_address_invalid';
  end;
end $$;

-- ---------------------------------------------------------------- dépôt de la photo
select :'org' || '/' || :'evt' || '/Couv_8f3a91c2.jpg' as good_path \gset
select set_config('test.wrong_path', :'other_org' || '/' || :'evt' || '/Couv_8f3a91c2.jpg', false) \gset ignored_

-- Les identifiants passent par des réglages de session : un contrôleur ou un
-- étranger ne voit pas forcément l'événement.
select set_config('test.cover_dir', :'org' || '/' || :'evt' || '/', false) \gset ignored_

-- Un contrôleur ne peut pas déposer de photo.
select test.login('cccccccc-0000-0000-0000-000000000003');
do $$
begin
  insert into storage.objects (bucket_id, name)
  values ('event-covers', current_setting('test.cover_dir') || 'Ctrl_12345678.jpg');
  raise exception 'ÉCHEC  dépôt par un contrôleur accepté';
exception when insufficient_privilege then
  raise notice 'OK    Dépôt de photo refusé au contrôleur';
end $$;

-- Un membre d'une autre organisation non plus.
select test.login('cccccccc-0000-0000-0000-000000000004');
do $$
begin
  insert into storage.objects (bucket_id, name)
  values ('event-covers', current_setting('test.cover_dir') || 'Etrg_12345678.jpg');
  raise exception 'ÉCHEC  dépôt par un étranger accepté';
exception when insufficient_privilege then
  raise notice 'OK    Dépôt de photo refusé hors de l''organisation';
end $$;

-- Le gestionnaire dépose : nom de fichier et dossier contrôlés.
select test.login('cccccccc-0000-0000-0000-000000000002');
do $$
declare
  v_bad text[] := array[
    'pas-un-dossier.jpg',
    '%s/%s/court.jpg',
    '%s/%s/Couverture_ok.exe',
    '%s/%s/../Couverture_ok.jpg',
    '%s/%s/sous/Couverture_ok.jpg'
  ];
  v_name text;
  v_evt public.events%rowtype;
begin
  select * into v_evt from public.events where title = 'Festival des Masques';
  foreach v_name in array v_bad loop
    begin
      insert into storage.objects (bucket_id, name)
      values ('event-covers', format(v_name, v_evt.organization_id, v_evt.id));
      raise exception 'ÉCHEC  chemin « % » accepté', v_name;
    exception when insufficient_privilege then
      null;
    end;
  end loop;
  raise notice 'OK    Chemins de photo mal formés refusés (5 cas)';
end $$;

insert into storage.objects (bucket_id, name) values ('event-covers', :'good_path');
select test.check('Gestionnaire : photo déposée dans le bon dossier',
  (select count(*) from storage.objects where name = :'good_path')::text, '1');

do $$
begin
  perform public.set_event_cover((select id from public.events where title = 'Festival des Masques'),
    (select organization_id || '/' || id || '/Absente_1234.jpg' from public.events
     where title = 'Festival des Masques'));
  raise exception 'ÉCHEC  photo absente rattachée';
exception when invalid_parameter_value then
  if sqlerrm <> 'event_cover_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Rattachement d''une photo absente refusé';
end $$;

do $$
declare
  v_evt public.events%rowtype;
begin
  select * into v_evt from public.events where title = 'Festival des Masques';
  perform public.set_event_cover(v_evt.id, current_setting('test.wrong_path'));
  raise exception 'ÉCHEC  photo d''une autre organisation rattachée';
exception when invalid_parameter_value then
  raise notice 'OK    Rattachement hors du dossier de l''événement refusé';
end $$;

-- Publication refusée tant que la photo manque, même avec la ville.
do $$
begin
  perform public.set_event_status((select id from public.events where title = 'Festival des Masques'),
                                  'published');
  raise exception 'ÉCHEC  publication sans photo';
exception when object_not_in_prerequisite_state then
  if sqlerrm <> 'event_incomplete' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Publication sans photo refusée (event_incomplete)';
end $$;

select test.check('Photo rattachée',
  (public.set_event_cover(:'evt', :'good_path')).cover_path, :'good_path');
select test.check('Publication avec photo et ville',
  (public.set_event_status(:'evt', 'published')).status::text, 'published');

-- Une fois publié : la photo et la ville restent obligatoires.
do $$
begin
  perform public.set_event_cover((select id from public.events where title = 'Festival des Masques'), null);
  raise exception 'ÉCHEC  photo retirée d''un événement publié';
exception when object_not_in_prerequisite_state then
  raise notice 'OK    Retrait de la photo refusé une fois publié';
end $$;
do $$
declare
  v_evt public.events%rowtype;
begin
  select * into v_evt from public.events where title = 'Festival des Masques';
  perform public.update_event(v_evt.id, v_evt.title, v_evt.starts_at, v_evt.ends_at, v_evt.timezone);
  raise exception 'ÉCHEC  ville retirée d''un événement publié';
exception when object_not_in_prerequisite_state then
  if sqlerrm <> 'event_incomplete' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Retrait de la ville refusé une fois publié';
end $$;

-- Un contrôleur ne peut pas changer la photo.
select test.login('cccccccc-0000-0000-0000-000000000003');
do $$
begin
  perform public.set_event_cover((select id from public.events where title = 'Festival des Masques'), null);
  raise exception 'ÉCHEC  photo modifiée par un contrôleur';
exception when insufficient_privilege then
  raise notice 'OK    Changement de photo refusé au contrôleur';
end $$;

-- Suppression d'un fichier : l'étranger ne voit ni ne supprime rien.
select test.login('cccccccc-0000-0000-0000-000000000004');
with d as (delete from storage.objects where name = :'good_path' returning 1)
select test.check('Étranger : suppression sans effet', count(*)::text, '0') from d;

-- Le propriétaire lit le journal.
select test.login('cccccccc-0000-0000-0000-000000000001');
select test.check('Journal : changement de photo tracé',
  (select count(*) from public.audit_logs
   where resource_id = :'evt' and action = 'event.cover_changed')::text, '1');

-- Le gestionnaire peut supprimer un ancien fichier de son événement.
select test.login('cccccccc-0000-0000-0000-000000000002');
select :'org' || '/' || :'evt' || '/Ancienne_1234.jpg' as old_path \gset
insert into storage.objects (bucket_id, name) values ('event-covers', :'old_path');
with d as (delete from storage.objects where name = :'old_path' returning 1)
select test.check('Gestionnaire : ancien fichier supprimé', count(*)::text, '1') from d;

reset role;
