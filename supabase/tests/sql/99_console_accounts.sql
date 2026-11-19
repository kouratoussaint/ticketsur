-- =============================================================================
-- Tikéo — Tests : comptes dans la console (migration 2200)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2200-0000-0000-000000000001', 'admin-comptes@test.local'),
  ('aaaaaaaa-2200-0000-0000-000000000002', 'promoteur-comptes@test.local'),
  ('aaaaaaaa-2200-0000-0000-000000000003', 'controleur-comptes@test.local'),
  ('aaaaaaaa-2200-0000-0000-000000000004', 'recent-comptes@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-2200-0000-0000-000000000001';
update public.profiles set display_name = 'Zénabou Promotrice'
 where id = 'aaaaaaaa-2200-0000-0000-000000000002';

-- Le promoteur a une structure, un événement et un ticket émis.
set role authenticated;
select test.login('aaaaaaaa-2200-0000-0000-000000000002');
select (public.create_organization('Studio Zénabou Comptes')::jsonb)->>'id' as org \gset
select (public.create_event(:'org', 'Concert Zénabou Comptes', now() + interval '2 days',
                            now() + interval '2 days 4 hours')).id as ev \gset
select (public.create_ticket_category(:'ev', 'Standard')).id as cat \gset
select test.complete_event(:'ev') \gset ignored_
select public.set_event_status(:'ev', 'published') \gset ignored_
select ticket_id as tk from public.issue_tickets(:'ev', :'cat', 1) \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-2200-0000-0000-000000000003', 'controller');
set role authenticated;

-- Demande de suppression par le promoteur ; une autre, récente.
select test.login('aaaaaaaa-2200-0000-0000-000000000002');
select public.request_account_deletion(true) \gset ignored_
select test.login('aaaaaaaa-2200-0000-0000-000000000004');
select public.request_account_deletion(true) \gset ignored_

-- Compte ordinaire : aucun accès ---------------------------------------------
select test.login('aaaaaaaa-2200-0000-0000-000000000003');
do $$
begin
  begin
    perform public.admin_accounts();
    raise exception 'ÉCHEC  liste des comptes lue sans être administrateur';
  exception when insufficient_privilege then
    raise notice 'OK    Liste des comptes réservée aux administrateurs';
  end;
  begin
    perform public.admin_purge_due_accounts();
    raise exception 'ÉCHEC  purge lancée sans être administrateur';
  exception when insufficient_privilege then
    raise notice 'OK    Suppression définitive réservée aux administrateurs';
  end;
end $$;

-- Liste et recherche -------------------------------------------------------------
select test.login('aaaaaaaa-2200-0000-0000-000000000001');
select test.check('Recherche sans accents : nom, adresse, structures',
  (select display_name || '|' || email || '|' || owned_structures || '|' || memberships
   from public.admin_accounts('zenabou promotrice')),
  'Zénabou Promotrice|promoteur-comptes@test.local|1|1');
select test.check('Recherche par adresse',
  (select count(*)::text from public.admin_accounts('CONTROLEUR-COMPTES@')), '1');
select test.check('Filtre « suppression demandée »',
  (select string_agg(email, ',' order by email) from public.admin_accounts('comptes', 'deletion')),
  'promoteur-comptes@test.local,recent-comptes@test.local');
select test.check('Échéance à 30 jours',
  (select (deletion_due_at - deletion_requested_at)::text
   from public.admin_accounts('promoteur-comptes')), '30 days');
select test.check('Filtre « à supprimer » : rien avant 30 jours',
  (select count(*)::text from public.admin_accounts('comptes', 'due')), '0');

-- Désactivation ---------------------------------------------------------------
do $$
begin
  begin
    perform public.admin_set_account_status('aaaaaaaa-2200-0000-0000-000000000003', 'disabled', '');
    raise exception 'ÉCHEC  désactivation sans motif';
  exception when invalid_parameter_value then
    raise notice 'OK    Désactivation : motif obligatoire';
  end;
  begin
    perform public.admin_set_account_status('aaaaaaaa-2200-0000-0000-000000000001', 'disabled', 'test');
    raise exception 'ÉCHEC  administrateur désactivé par lui-même';
  exception when insufficient_privilege then
    raise notice 'OK    On ne se désactive pas soi-même';
  end;
end $$;
select public.admin_set_account_status('aaaaaaaa-2200-0000-0000-000000000003', 'disabled',
                                       'Comportement abusif') \gset ignored_
select test.check('Compte désactivé, motif sur le profil',
  (select status || '|' || disabled_reason from public.admin_accounts('controleur-comptes')),
  'disabled|Comportement abusif');
select test.check('Désactivation journalisée sans motif',
  (select details::text from public.admin_audit_logs('admin.account_status_changed', 100)
   where resource_id = 'aaaaaaaa-2200-0000-0000-000000000003'),
  '{"status": "disabled"}');
select test.login('aaaaaaaa-2200-0000-0000-000000000003');
select test.check('Compte désactivé : plus de poste de contrôle ni de structure',
  ((select count(*) from public.my_scan_posts())
   + (select count(*) from public.my_organizations()))::text, '0');
select test.login('aaaaaaaa-2200-0000-0000-000000000001');
select public.admin_set_account_status('aaaaaaaa-2200-0000-0000-000000000003', 'active') \gset ignored_
select test.check('Réactivation : motif effacé',
  (select status || '|' || coalesce(disabled_reason, '∅')
   from public.admin_accounts('controleur-comptes')),
  'active|∅');

-- Suppression définitive ----------------------------------------------------------
do $$
begin
  begin
    perform public.admin_purge_account('aaaaaaaa-2200-0000-0000-000000000004');
    raise exception 'ÉCHEC  compte supprimé avant 30 jours';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Suppression refusée avant 30 jours';
  end;
end $$;

-- 31 jours plus tard pour le promoteur.
reset role;
update public.profiles set deletion_requested_at = now() - interval '31 days'
 where id = 'aaaaaaaa-2200-0000-0000-000000000002';
set role authenticated;
select test.login('aaaaaaaa-2200-0000-0000-000000000001');
select test.check('Filtre « à supprimer » : le promoteur',
  (select string_agg(email, ',') from public.admin_accounts('comptes', 'due')),
  'promoteur-comptes@test.local');
select public.admin_overview()::text as ov \gset
select test.check('Vue d''ensemble : comptes à supprimer comptés',
  (((:'ov'::jsonb)->'accounts'->>'deletion_due')::int >= 1)::text, 'true');

select public.admin_purge_due_accounts()::text as purge \gset
select test.check('Purge : au moins notre compte, sa structure suspendue',
  (((:'purge'::jsonb)->>'accounts')::int >= 1
   and ((:'purge'::jsonb)->>'structures_suspended')::int >= 1)::text, 'true');

reset role;
select test.check('Structure du propriétaire suspendue',
  (select status || '|' || disabled_reason from public.organizations where id = :'org'),
  'disabled|Compte du propriétaire supprimé.');
select test.check('Profil anonymisé',
  (select display_name || '|' || status || '|' || (deleted_at is not null)
   || '|' || coalesce(phone, '∅') || '|' || coalesce(avatar_path, '∅')
   from public.profiles where id = 'aaaaaaaa-2200-0000-0000-000000000002'),
  'Compte supprimé|disabled|true|∅|∅');
select test.check('Compte d''authentification vidé et banni',
  (select email || '|' || raw_user_meta_data::text || '|' || (banned_until = 'infinity')
   from auth.users where id = 'aaaaaaaa-2200-0000-0000-000000000002'),
  'supprime-aaaaaaaa-2200-0000-0000-000000000002@supprime.invalid|{}|true');
select test.check('Appartenances désactivées, ticket conservé',
  (select count(*) from public.organization_members
    where user_id = 'aaaaaaaa-2200-0000-0000-000000000002' and active)::text
  || '|' || (select count(*) from public.tickets where id = :'tk')::text,
  '0|1');
select test.check('Journal : suppression sans donnée personnelle',
  (select details::text from public.audit_logs
   where action = 'admin.account_purged' and resource_id = 'aaaaaaaa-2200-0000-0000-000000000002'),
  '{"structures_suspended": 1}');
select test.check('Journal : suspension de la structure, cause',
  (select details::text from public.audit_logs
   where action = 'admin.organization_status_changed' and resource_id = :'org'),
  '{"cause": "owner_deleted", "status": "disabled"}');
set role authenticated;
select test.login('aaaaaaaa-2200-0000-0000-000000000001');
select test.check('Compte supprimé : filtre « supprimés », plus « à supprimer »',
  (select count(*) from public.admin_accounts('compte supprime', 'deleted')
    where id = 'aaaaaaaa-2200-0000-0000-000000000002')::text
  || '|' || (select count(*) from public.admin_accounts(null, 'due')
    where id = 'aaaaaaaa-2200-0000-0000-000000000002')::text,
  '1|0');
do $$
begin
  begin
    perform public.admin_purge_account('aaaaaaaa-2200-0000-0000-000000000002');
    raise exception 'ÉCHEC  compte supprimé deux fois';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Compte déjà supprimé : refusé';
  end;
  begin
    perform public.admin_set_account_status('aaaaaaaa-2200-0000-0000-000000000002', 'active');
    raise exception 'ÉCHEC  compte supprimé réactivé';
  exception when object_not_in_prerequisite_state then
    raise notice 'OK    Compte supprimé : pas de réactivation';
  end;
end $$;

-- Le compte récent n'a pas été touché.
reset role;
select test.check('Compte récent intact',
  (select display_name || '|' || (deleted_at is null) from public.profiles
   where id = 'aaaaaaaa-2200-0000-0000-000000000004'),
  'recent-comptes|true');
