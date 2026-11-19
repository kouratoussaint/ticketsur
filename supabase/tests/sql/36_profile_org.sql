-- =============================================================================
-- TicketSûr — Tests : profil et fiche d'organisation (migration 1200)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email, raw_user_meta_data) values
  ('dddddddd-0000-0000-0000-000000000001', 'awa@test.local', '{"display_name": "Awa"}'),
  ('dddddddd-0000-0000-0000-000000000002', 'issa@test.local', '{}'),
  ('dddddddd-0000-0000-0000-000000000003', 'moussa@test.local', '{}');

set role authenticated;

-- ---------------------------------------------------------------- profil
select test.login('dddddddd-0000-0000-0000-000000000001');
select test.check('Profil : lecture du sien',
  (select display_name || '|' || locale from public.my_profile()), 'Awa|fr');
select test.check('Profil : nom nettoyé, téléphone burkinabè normalisé',
  (select display_name || '|' || phone
   from public.update_my_profile('  Awa   Ouédraogo ', '70 12 34 56', 'fr')),
  'Awa Ouédraogo|+22670123456');
select test.check('Profil : préfixe 00 converti',
  (select phone from public.update_my_profile('Awa Ouédraogo', '00226 76 00 00 01', 'en')),
  '+22676000001');
select test.check('Profil : langue enregistrée',
  (select locale from public.my_profile()), 'en');
select test.check('Profil : téléphone effacé',
  (select coalesce(phone, '∅') from public.update_my_profile('Awa Ouédraogo', '  ', 'fr')), '∅');

do $$
begin
  begin
    perform public.update_my_profile('A');
    raise exception 'ÉCHEC  nom d''une lettre accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'profile_name_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus profile_name_invalid';
  end;
  begin
    perform public.update_my_profile('Awa', '+12');
    raise exception 'ÉCHEC  téléphone trop court accepté';
  exception when invalid_parameter_value then
    if sqlerrm <> 'profile_phone_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
    raise notice 'OK    Refus profile_phone_invalid';
  end;
  begin
    perform public.update_my_profile('Awa', null, 'de');
    raise exception 'ÉCHEC  langue inconnue acceptée';
  exception when invalid_parameter_value then
    raise notice 'OK    Refus profile_locale_invalid';
  end;
end $$;

-- Écriture directe interdite (RPC obligatoire).
do $$
begin
  update public.profiles set display_name = 'Piraté';
  raise exception 'ÉCHEC  écriture directe du profil acceptée';
exception when insufficient_privilege then
  raise notice 'OK    Écriture directe du profil refusée';
end $$;

-- Photo de profil : dossier personnel seulement.
select set_config('test.avatar', 'dddddddd-0000-0000-0000-000000000001/Avatar_9f8e7d6c.jpg', false)
  \gset ignored_
insert into storage.objects (bucket_id, name) values ('avatars', current_setting('test.avatar'));
select test.check('Avatar : photo rattachée',
  (select avatar_path from public.set_my_avatar(current_setting('test.avatar'))),
  'dddddddd-0000-0000-0000-000000000001/Avatar_9f8e7d6c.jpg');
do $$
begin
  insert into storage.objects (bucket_id, name)
  values ('avatars', 'dddddddd-0000-0000-0000-000000000002/Intrus_12345678.jpg');
  raise exception 'ÉCHEC  dépôt dans le dossier d''un autre accepté';
exception when insufficient_privilege then
  raise notice 'OK    Dépôt d''avatar hors de son dossier refusé';
end $$;

select test.login('dddddddd-0000-0000-0000-000000000002');
do $$
begin
  perform public.set_my_avatar('dddddddd-0000-0000-0000-000000000001/Avatar_9f8e7d6c.jpg');
  raise exception 'ÉCHEC  avatar d''autrui rattaché';
exception when invalid_parameter_value then
  raise notice 'OK    Rattachement de l''avatar d''un autre refusé';
end $$;
with d as (delete from storage.objects
           where name = 'dddddddd-0000-0000-0000-000000000001/Avatar_9f8e7d6c.jpg' returning 1)
select test.check('Avatar d''autrui : suppression sans effet', count(*)::text, '0') from d;

-- Demande de suppression du compte, puis annulation.
select test.check('Suppression du compte demandée',
  (public.request_account_deletion(true) is not null)::text, 'true');
select test.check('Demande conservée à la seconde demande',
  (select (deletion_requested_at is not null)::text from public.my_profile()), 'true');
select test.check('Suppression annulée',
  coalesce(public.request_account_deletion(false)::text, '∅'), '∅');

-- ---------------------------------------------------------------- organisation
select test.login('dddddddd-0000-0000-0000-000000000001');
select (public.create_organization('Studio Awa')::jsonb)->>'id' as org \gset
select set_config('test.org', :'org', false) \gset ignored_

reset role;
insert into public.organization_members (organization_id, user_id, role) values
  (:'org', 'dddddddd-0000-0000-0000-000000000002', 'manager'),
  (:'org', 'dddddddd-0000-0000-0000-000000000003', 'controller');
insert into public.events (id, organization_id, title, starts_at, ends_at)
values ('dddddddd-0000-0000-0000-0000000000e1', :'org', 'Soirée',
        now() + interval '2 days', now() + interval '2 days 4 hours');
insert into public.event_assignments (event_id, user_id)
values ('dddddddd-0000-0000-0000-0000000000e1', 'dddddddd-0000-0000-0000-000000000003');
set role authenticated;

select test.login('dddddddd-0000-0000-0000-000000000001');
select test.check('Fiche : propriétaire modifie nom, téléphone, e-mail, ville',
  (select name || '|' || phone || '|' || contact_email || '|' || city
   from public.update_organization(:'org', ' Studio  Awa ', '+226 25 30 00 00',
                                   ' Contact@Studio.BF ', 'Ouagadougou')),
  'Studio Awa|+22625300000|contact@studio.bf|Ouagadougou');
select test.check('my_organizations expose la fiche',
  (select contact_email || '|' || city from public.my_organizations() where id = :'org'),
  'contact@studio.bf|Ouagadougou');

do $$
begin
  perform public.update_organization(current_setting('test.org')::uuid, 'Studio', null, 'pas-un-mail');
  raise exception 'ÉCHEC  e-mail invalide accepté';
exception when invalid_parameter_value then
  if sqlerrm <> 'org_email_invalid' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Refus org_email_invalid';
end $$;

-- Logo : propriétaire seulement.
select set_config('test.logo', :'org' || '/Logo_a1b2c3d4.png', false) \gset ignored_
insert into storage.objects (bucket_id, name) values ('org-logos', current_setting('test.logo'));
select test.check('Logo rattaché',
  (public.set_organization_logo(:'org', current_setting('test.logo'))).logo_path,
  current_setting('test.logo'));

select test.login('dddddddd-0000-0000-0000-000000000002');
do $$
begin
  perform public.update_organization(current_setting('test.org')::uuid, 'Pris par le gestionnaire');
  raise exception 'ÉCHEC  gestionnaire modifie la fiche';
exception when insufficient_privilege then
  raise notice 'OK    Fiche réservée au propriétaire (gestionnaire refusé)';
end $$;
do $$
begin
  insert into storage.objects (bucket_id, name)
  values ('org-logos', current_setting('test.org') || '/Gest_12345678.png');
  raise exception 'ÉCHEC  logo déposé par un gestionnaire';
exception when insufficient_privilege then
  raise notice 'OK    Dépôt de logo refusé au gestionnaire';
end $$;

-- ---------------------------------------------------------------- départ
-- Le contrôleur quitte : appartenance désactivée, affectations retirées.
select test.login('dddddddd-0000-0000-0000-000000000003');
select public.leave_organization(:'org') \gset ignored_
select test.check('Départ : organisation retirée de la liste',
  (select count(*) from public.my_organizations() where id = :'org')::text, '0');
reset role;
select test.check('Départ : affectations retirées',
  (select count(*) from public.event_assignments
   where user_id = 'dddddddd-0000-0000-0000-000000000003')::text, '0');
set role authenticated;

-- Le dernier propriétaire ne peut pas partir.
select test.login('dddddddd-0000-0000-0000-000000000001');
do $$
begin
  perform public.leave_organization(current_setting('test.org')::uuid);
  raise exception 'ÉCHEC  dernier propriétaire parti';
exception when object_not_in_prerequisite_state then
  if sqlerrm <> 'org_last_owner' then raise exception 'ÉCHEC  code %', sqlerrm; end if;
  raise notice 'OK    Départ du dernier propriétaire refusé';
end $$;

-- Un ancien membre n'est plus « membre ».
select test.login('dddddddd-0000-0000-0000-000000000003');
do $$
begin
  perform public.leave_organization(current_setting('test.org')::uuid);
  raise exception 'ÉCHEC  second départ accepté';
exception when insufficient_privilege then
  raise notice 'OK    Second départ refusé (plus membre)';
end $$;

select test.login('dddddddd-0000-0000-0000-000000000001');
select test.check('Journal : départ et mise à jour tracés',
  (select string_agg(action, ',' order by action) from public.audit_logs
   where organization_id = :'org'
     and action in ('member.left', 'organization.updated', 'organization.logo_changed')),
  'member.left,organization.logo_changed,organization.updated');

reset role;
