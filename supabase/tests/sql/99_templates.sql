-- =============================================================================
-- Tikéo — Tests : modèles de tickets, accroche, numéro d'ordre (migration 3100)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-3100-0000-0000-000000000001', 'proprio-modele@test.local'),
  ('aaaaaaaa-3100-0000-0000-000000000002', 'controleur-modele@test.local');

set role authenticated;
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select (public.create_organization('Studio Modèle Qtw')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Modèle Qtw', now() + interval '3 days',
                            now() + interval '3 days 3 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'VIP')).id as cat \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as std \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-3100-0000-0000-000000000002', 'controller');
select set_config('test.cat', :'cat', false) \gset ignored_
select set_config('test.ev', :'ev', false) \gset ignored_
set role authenticated;

-- Numéro d'ordre -----------------------------------------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select array_agg(ticket_id)::text as first from public.issue_tickets(:'ev', :'cat', 3) \gset
select array_agg(ticket_id)::text as second from public.issue_named_tickets(:'ev',
  jsonb_build_array(jsonb_build_object('category_id', :'std', 'name', 'Awa Test'))) \gset
reset role;
select test.check('Numéros 1 à 4 dans l''ordre d''émission, toutes catégories',
  (select string_agg(event_number::text, ',' order by event_number)
     from public.tickets where event_id = :'ev'), '1,2,3,4');
set role authenticated;
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select test.check('ticket_art_info : catégorie et numéro',
  (select string_agg(event_number || ':' || (category_id = :'cat'::uuid)::text, ',' order by event_number)
     from public.ticket_art_info(:'first'::uuid[] || :'second'::uuid[])),
  '1:true,2:true,3:true,4:false');
select test.login('aaaaaaaa-3100-0000-0000-000000000002');
select test.check('ticket_art_info : rien pour un contrôleur',
  (select count(*)::text from public.ticket_art_info(:'first'::uuid[])), '0');

-- Accroche -----------------------------------------------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select public.set_event_tagline(:'ev', '  La nuit des étoiles  ') \gset ignored_
reset role;
select test.check('Accroche enregistrée sans espaces autour',
  (select tagline from public.events where id = :'ev'), 'La nuit des étoiles');
set role authenticated;
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
do $$
begin
  begin
    perform public.set_event_tagline(current_setting('test.ev')::uuid, repeat('x', 61));
    raise exception 'ÉCHEC  accroche trop longue acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'event_tagline_invalid' then raise; end if;
    raise notice 'OK    Accroche de plus de 60 caractères refusée';
  end;
end $$;
select test.login('aaaaaaaa-3100-0000-0000-000000000002');
do $$
begin
  begin
    perform public.set_event_tagline(current_setting('test.ev')::uuid, 'Pirate');
    raise exception 'ÉCHEC  accroche modifiée par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Accroche réservée aux gestionnaires';
  end;
end $$;

-- Modèle intégré -----------------------------------------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select public.set_ticket_template(:'cat', '{"kind":"builtin","builtin_theme":5,"single_font_title":true}') \gset ignored_
select test.check('Modèle intégré enregistré',
  (select (template->>'kind') || ':' || (template->>'builtin_theme') || ':'
          || (template->>'single_font_title')
     from public.event_ticket_templates(:'ev')), 'builtin:5:true');
do $$
begin
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid, '{"kind":"builtin","builtin_theme":13}');
    raise exception 'ÉCHEC  thème 13 accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_invalid' then raise; end if;
    raise notice 'OK    Thème inconnu refusé';
  end;
end $$;
select test.login('aaaaaaaa-3100-0000-0000-000000000002');
do $$
begin
  begin
    perform public.event_ticket_templates(current_setting('test.ev')::uuid);
    raise exception 'ÉCHEC  modèles lus par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Modèles réservés aux gestionnaires';
  end;
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid, '{"kind":"builtin","builtin_theme":1}');
    raise exception 'ÉCHEC  modèle modifié par un contrôleur';
  exception when insufficient_privilege then
    raise notice 'OK    Modèle modifiable par les seuls gestionnaires';
  end;
end $$;

-- Modèle importé -----------------------------------------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select :'org' || '/' || :'ev' || '/Modele_12345678.jpg' as img \gset
select set_config('test.img', :'img', false) \gset ignored_
do $$
begin
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid, jsonb_build_object(
      'kind', 'custom', 'image_path', current_setting('test.img'), 'image_width', 2400,
      'image_height', 1000, 'qr_x', 0.8, 'qr_y', 0.2, 'qr_size', 0.45, 'ref_x', 0.9, 'ref_y', 0.7));
    raise exception 'ÉCHEC  image absente acceptée';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_image_invalid' then raise; end if;
    raise notice 'OK    Image de modèle absente refusée';
  end;
end $$;
insert into storage.objects (bucket_id, name) values ('event-covers', :'img');
do $$
declare
  v_base jsonb := jsonb_build_object('kind', 'custom', 'image_path', current_setting('test.img'),
    'image_width', 2400, 'image_height', 1000, 'qr_x', 0.78, 'qr_y', 0.2, 'ref_x', 0.9, 'ref_y', 0.75);
begin
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid, v_base || '{"qr_size":0.3}');
    raise exception 'ÉCHEC  QR trop petit accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_qr_too_small' then raise; end if;
    raise notice 'OK    QR sous 35 %% de la hauteur refusé';
  end;
  begin
    -- 0,78 + 0,6 × 1000 / 2400 = 1,03 : dépasse à droite.
    perform public.set_ticket_template(current_setting('test.cat')::uuid, v_base || '{"qr_size":0.6}');
    raise exception 'ÉCHEC  QR hors du ticket accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_invalid' then raise; end if;
    raise notice 'OK    QR hors du ticket refusé';
  end;
  perform public.set_ticket_template(current_setting('test.cat')::uuid, v_base || '{"qr_size":0.5}');
end $$;
select test.check('Modèle importé enregistré (remplace le thème intégré)',
  (select (template->>'kind') || ':' || coalesce(template->>'builtin_theme', '-') || ':'
          || (template->>'qr_size')
     from public.event_ticket_templates(:'ev')), 'custom:-:0.5');
-- Titulaire placé : les deux coordonnées ou aucune.
do $$
declare
  v_base jsonb := jsonb_build_object('kind', 'custom', 'image_path', current_setting('test.img'),
    'image_width', 2400, 'image_height', 1000, 'qr_x', 0.78, 'qr_y', 0.2, 'qr_size', 0.5,
    'ref_x', 0.9, 'ref_y', 0.75);
begin
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid, v_base || '{"holder_x":0.2}');
    raise exception 'ÉCHEC  titulaire à moitié placé accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_invalid' then raise; end if;
    raise notice 'OK    Titulaire : deux coordonnées ou aucune';
  end;
  perform public.set_ticket_template(current_setting('test.cat')::uuid,
    v_base || '{"holder_x":0.2,"holder_y":0.8}');
end $$;
select test.check('Titulaire placé sur le design',
  (select (template->>'holder_x') || ',' || (template->>'holder_y')
     from public.event_ticket_templates(:'ev')), '0.2,0.8');
-- Cadrage de la photo d'un thème intégré.
do $$
begin
  begin
    perform public.set_ticket_template(current_setting('test.cat')::uuid,
      '{"kind":"builtin","builtin_theme":2,"cover_zoom":4}');
    raise exception 'ÉCHEC  zoom de 4 accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'template_invalid' then raise; end if;
    raise notice 'OK    Zoom de la photo entre 1 et 3';
  end;
end $$;
select public.set_ticket_template(:'cat',
  '{"kind":"builtin","builtin_theme":2,"cover_x":0.3,"cover_y":0.6,"cover_zoom":1.5}') \gset ignored_
select test.check('Cadrage de la photo enregistré ; placement du design effacé',
  (select concat_ws(',', template->>'cover_x', template->>'cover_y', template->>'cover_zoom',
                    coalesce(template->>'holder_x', '-'))
     from public.event_ticket_templates(:'ev')), '0.3,0.6,1.5,-');

-- Mes tickets : numéro, accroche, modèle -----------------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000002');
select test.check('Mes tickets : rien tant que le ticket n''est pas ajouté',
  (select count(*)::text from public.my_tickets()), '0');
reset role;
update public.tickets set holder_user_id = 'aaaaaaaa-3100-0000-0000-000000000002'
 where id = (:'first'::uuid[])[2];
set role authenticated;
select test.login('aaaaaaaa-3100-0000-0000-000000000002');
select test.check('Mes tickets : numéro, accroche et modèle de la catégorie',
  (select event_number || '|' || tagline || '|' || (template->>'builtin_theme')
     from public.my_tickets()), '2|La nuit des étoiles|2');

-- Duplication : accroche et thème intégré recopiés -------------------------------
select test.login('aaaaaaaa-3100-0000-0000-000000000001');
select public.duplicate_event(:'ev', 'Concert Modèle Qtw bis', now() + interval '10 days',
                              now() + interval '10 days 3 hours') as dup \gset
reset role;
select test.check('Duplication : accroche recopiée',
  (select tagline from public.events where id = :'dup'), 'La nuit des étoiles');
select test.check('Duplication : thème intégré recopié sur la catégorie de même nom',
  (select c.name || ':' || m.builtin_theme || ':' || m.cover_zoom
     from public.ticket_category_templates m
     join public.ticket_categories c on c.id = m.category_id
    where c.event_id = :'dup'), 'VIP:2:1.5');
set role authenticated;
select test.login('aaaaaaaa-3100-0000-0000-000000000001');

select public.set_ticket_template(:'cat', null) \gset ignored_
select test.check('Modèle retiré : retour au modèle proposé',
  (select count(*)::text from public.event_ticket_templates(:'ev')), '0');
reset role;
select test.check('Journal des modèles sans donnée personnelle',
  (select string_agg(distinct details->>'kind', ',' order by details->>'kind') from public.audit_logs
    where action = 'ticket_template.updated' and organization_id = :'org'),
  'builtin,custom,default');
