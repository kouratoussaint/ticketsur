-- =============================================================================
-- Tikéo — Tests : rôles d'administration et gestion des comptes (migration 4900)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
-- created_at explicite : sur Supabase, la colonne n'a pas de valeur par
-- défaut (GoTrue la remplit) ; « compte créé il y a moins de 10 minutes »
-- en dépend.
insert into auth.users (id, email, created_at) values
  ('aaaaaaaa-4900-0000-0000-000000000001', 'super-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000002', 'support-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000003', 'finance-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000004', 'moderation-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000005', 'awa-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000006', 'nouveau-roles@test.local', now()),
  ('aaaaaaaa-4900-0000-0000-000000000007', 'adieu-roles@test.local', now());
update public.profiles set is_platform_admin = true
 where id in ('aaaaaaaa-4900-0000-0000-000000000001', 'aaaaaaaa-4900-0000-0000-000000000002',
              'aaaaaaaa-4900-0000-0000-000000000003', 'aaaaaaaa-4900-0000-0000-000000000004');
-- 01 sans ligne de rôle : super par défaut.
insert into private.platform_admin_roles (user_id, role) values
  ('aaaaaaaa-4900-0000-0000-000000000002', 'support'),
  ('aaaaaaaa-4900-0000-0000-000000000003', 'finance'),
  ('aaaaaaaa-4900-0000-0000-000000000004', 'moderation');
insert into auth.sessions (id, user_id) values
  ('cccccccc-4900-0000-0000-000000000001', 'aaaaaaaa-4900-0000-0000-000000000005'),
  ('cccccccc-4900-0000-0000-000000000002', 'aaaaaaaa-4900-0000-0000-000000000005');
insert into public.account_devices (session_id, user_id, label, platform) values
  ('cccccccc-4900-0000-0000-000000000001', 'aaaaaaaa-4900-0000-0000-000000000005', 'Tecno', 'android');
-- Réglages de départ connus (le staging peut avoir été réglé).
update private.console_settings s set value = 'false'::jsonb where s.key in ('notify_users', 'admin_issue_tickets');
select coalesce(max(id), 0) as base from public.push_outbox \gset

-- Rôles et permissions ------------------------------------------------------------
set role authenticated;
select test.login('aaaaaaaa-4900-0000-0000-000000000001');
select test.check('Sans ligne de rôle : super, toutes les permissions',
  (select (m->>'role') || ':' || (m->'permissions' ? 'admins')::text from public.admin_me() m),
  'super:true');
select test.login('aaaaaaaa-4900-0000-0000-000000000002');
select test.check('Support : comptes oui, facturation non',
  (select (m->>'role') || ':' || (m->'permissions' ? 'accounts')::text || ':'
          || (m->'permissions' ? 'billing')::text from public.admin_me() m),
  'support:true:false');

select test.login('aaaaaaaa-4900-0000-0000-000000000003');
select test.expect_error('Finance : désactiver un compte refusé (fonction existante)',
  $q$select public.admin_set_account_status('aaaaaaaa-4900-0000-0000-000000000005', 'disabled', 'x')$q$,
  'admin_role_forbidden');
select test.expect_error('Finance : réponse type refusée (fonction existante)',
  $q$select public.admin_save_support_template(null, 'Titre', 'Corps')$q$, 'admin_role_forbidden');
select test.check('Finance : lecture des listes permise',
  (select (count(*) >= 0)::text from public.admin_accounts(null, 'all', 5, 0)), 'true');
select test.login('aaaaaaaa-4900-0000-0000-000000000004');
select test.expect_error('Modération : modifier un compte refusé',
  $q$select public.admin_update_account('aaaaaaaa-4900-0000-0000-000000000005', 'Awa', null, 'Motif')$q$,
  'admin_role_forbidden');

-- Support : comptes -----------------------------------------------------------------
select test.login('aaaaaaaa-4900-0000-0000-000000000002');
select public.admin_update_account('aaaaaaaa-4900-0000-0000-000000000005', 'Awa Kaboré',
  '70 11 22 33', 'Demande au guichet') \gset ignored_
reset role;
select test.check('Compte modifié, téléphone normalisé',
  (select display_name || '|' || phone from public.profiles
    where id = 'aaaaaaaa-4900-0000-0000-000000000005'),
  'Awa Kaboré|+22670112233');
set role authenticated;
select test.login('aaaaaaaa-4900-0000-0000-000000000002');
select test.expect_error('Motif obligatoire',
  $q$select public.admin_update_account('aaaaaaaa-4900-0000-0000-000000000005', 'Awa', null, ' ')$q$,
  'reason_required');
select test.expect_error('Compte d''un administrateur : réservé au super',
  $q$select public.admin_update_account('aaaaaaaa-4900-0000-0000-000000000001', 'Chef', null, 'Motif')$q$,
  'account_admin_protected');
select test.expect_error('Son propre compte : refusé',
  $q$select public.admin_sign_out_account('aaaaaaaa-4900-0000-0000-000000000002', 'Motif')$q$,
  'self_forbidden');
select test.check('Déconnexion de tous les appareils (prévenir coché)',
  public.admin_sign_out_account('aaaaaaaa-4900-0000-0000-000000000005', 'Téléphone volé', true)::text,
  '2');
reset role;
select test.check('Sessions et appareils retirés',
  (select (select count(*) from auth.sessions where user_id = 'aaaaaaaa-4900-0000-0000-000000000005')
          || ':' || (select count(*) from public.account_devices
                      where user_id = 'aaaaaaaa-4900-0000-0000-000000000005')),
  '0:0');
select test.check('Notification seulement quand demandée (réglage : non)',
  (select string_agg(o.title || ' / ' || o.body, ',') from public.push_outbox o
    where o.id > :base and o.user_id = 'aaaaaaaa-4900-0000-0000-000000000005'),
  'Vous avez été déconnecté de Tikéo / Par l''équipe Tikéo. Motif : Téléphone volé');
set role authenticated;
select test.login('aaaaaaaa-4900-0000-0000-000000000002');
select test.expect_error('Annuler une suppression non demandée',
  $q$select public.admin_cancel_account_deletion('aaaaaaaa-4900-0000-0000-000000000005', 'Motif')$q$,
  'deletion_not_requested');
select test.check('Fiche : téléphone, appareils, motifs des actions',
  (select (d->>'phone') || ':' || jsonb_array_length(d->'devices') || ':'
          || (d->'actions'->0->>'reason') || ':' || (d->'actions'->0->>'action')
     from public.admin_account_detail('aaaaaaaa-4900-0000-0000-000000000005') d),
  '+22670112233:0:Téléphone volé:admin.account_signed_out');
select test.expect_error('Support : création sans double authentification',
  $q$select public.admin_account_guard('create')$q$, 'admin_mfa_needed');
select test.expect_error('Support : suppression immédiate refusée',
  $q$select public.admin_delete_account_now('aaaaaaaa-4900-0000-0000-000000000007', 'adieu-roles@test.local', 'Motif')$q$,
  'admin_role_forbidden');
select test.expect_error('Support : rôles refusés',
  $q$select public.admin_set_admin_role('aaaaaaaa-4900-0000-0000-000000000005', 'support', 'Motif')$q$,
  'admin_role_forbidden');
select test.expect_error('Support : réglages refusés',
  $q$select public.admin_save_console_settings(true, null)$q$, 'admin_role_forbidden');

-- Super ------------------------------------------------------------------------------
select test.login('aaaaaaaa-4900-0000-0000-000000000001');
select test.check('Réglages : prévenir par défaut',
  (public.admin_save_console_settings(true, null)->>'notify_users'), 'true');
select test.expect_error('Rôle sans double authentification',
  $q$select public.admin_set_admin_role('aaaaaaaa-4900-0000-0000-000000000003', 'support', 'Motif')$q$,
  'admin_mfa_needed');
reset role;
insert into auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at)
values ('bbbbbbbb-4900-0000-0000-000000000001', 'aaaaaaaa-4900-0000-0000-000000000001',
        'Tikéo roles', 'totp', 'verified', now(), now()),
       ('bbbbbbbb-4900-0000-0000-000000000002', 'aaaaaaaa-4900-0000-0000-000000000002',
        'Tikéo roles 2', 'totp', 'verified', now(), now());
set role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-4900-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select test.check('Rôle changé (finance → support)',
  public.admin_set_admin_role('aaaaaaaa-4900-0000-0000-000000000003', 'support', 'Changement d''équipe'),
  'support');
select test.expect_error('Rôle inconnu',
  $q$select public.admin_set_admin_role('aaaaaaaa-4900-0000-0000-000000000005', 'roi', 'Motif')$q$,
  'admin_role_invalid');
-- Dernier super : vérifié seulement si aucun autre super n'existe (le staging en a).
reset role;
select exists (select 1 from public.profiles p
                where p.is_platform_admin and p.id <> 'aaaaaaaa-4900-0000-0000-000000000001'
                  and private.admin_role_of(p.id) = 'super') as other_supers \gset
set role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-4900-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
\if :other_supers
\else
select test.expect_error('Dernier super administrateur gardé',
  $q$select public.admin_set_admin_role('aaaaaaaa-4900-0000-0000-000000000001', 'support', 'Motif')$q$,
  'last_super_admin');
\endif
select test.check('Administrateurs listés avec leur rôle',
  (select string_agg(a.role, ',' order by a.email) from public.admin_platform_admins() a
    where a.email like '%-roles@test.local'),
  'support,moderation,super,support');
select test.check('Création : contrôle passé avec double authentification',
  (select count(*)::text from (select public.admin_account_guard('create', null, '70 00 00 01')) g),
  '1');
select test.expect_error('Création : téléphone invalide',
  $q$select public.admin_account_guard('create', null, '12')$q$, 'profile_phone_invalid');
select public.admin_record_account_created('aaaaaaaa-4900-0000-0000-000000000006',
  '70 99 88 77', 'Inscription au guichet') \gset ignored_
reset role;
update auth.users set created_at = now() - interval '1 day'
 where id = 'aaaaaaaa-4900-0000-0000-000000000005';
set role authenticated;
select set_config('request.jwt.claims',
  jsonb_build_object('sub', 'aaaaaaaa-4900-0000-0000-000000000001', 'role', 'authenticated',
                     'aal', 'aal2')::text, false) \gset ignored_
select test.expect_error('Enregistrement d''un compte ancien refusé',
  $q$select public.admin_record_account_created('aaaaaaaa-4900-0000-0000-000000000005', null, 'Motif')$q$,
  'account_not_new');
select public.admin_record_password_reset('aaaaaaaa-4900-0000-0000-000000000005',
  'Mot de passe oublié') \gset ignored_
select test.expect_error('Suppression : e-mail de confirmation faux',
  $q$select public.admin_delete_account_now('aaaaaaaa-4900-0000-0000-000000000007', 'autre@test.local', 'Motif')$q$,
  'confirmation_mismatch');
select test.check('Suppression immédiate',
  public.admin_delete_account_now('aaaaaaaa-4900-0000-0000-000000000007', ' ADIEU-roles@test.local ',
                                  'Demande écrite')::text, '0');
select public.admin_remove_account_mfa('aaaaaaaa-4900-0000-0000-000000000002',
  'Téléphone perdu') \gset ignored_

-- Le nouveau compte doit changer son mot de passe.
select test.login('aaaaaaaa-4900-0000-0000-000000000006');
select test.check('Nouveau compte : mot de passe à changer',
  public.my_account_flags()->>'must_change_password', 'true');
select public.clear_must_change_password() \gset ignored_
select test.check('Mot de passe changé : drapeau levé',
  public.my_account_flags()->>'must_change_password', 'false');

reset role;
select test.check('Comptes : téléphone du nouveau, mot de passe à changer, supprimé',
  (select string_agg(coalesce(p.phone, '-') || '/' || p.must_change_password || '/'
                     || (p.deleted_at is not null), ',' order by u.email)
     from public.profiles p join auth.users u on u.id = p.id
    where p.id in ('aaaaaaaa-4900-0000-0000-000000000005', 'aaaaaaaa-4900-0000-0000-000000000006',
                   'aaaaaaaa-4900-0000-0000-000000000007')),
  '+22670112233/true/false,+22670998877/false/false,-/false/true');
select test.check('Double authentification retirée',
  private.has_verified_factor('aaaaaaaa-4900-0000-0000-000000000002')::text, 'false');
select test.check('Réglage « prévenir » appliqué au mot de passe provisoire',
  (select count(*)::text from public.push_outbox o
    where o.id > :base and o.user_id = 'aaaaaaaa-4900-0000-0000-000000000005'
      and o.title = 'Nouveau mot de passe Tikéo'),
  '1');
select test.check('Journal sans motif ; motifs à part',
  (select bool_and(a.details::text not like '%volé%' and a.details::text not like '%guichet%')::text
          || ':' || (select count(*) from private.admin_action_log l
                      where l.target_id in ('aaaaaaaa-4900-0000-0000-000000000005',
                                            'aaaaaaaa-4900-0000-0000-000000000006',
                                            'aaaaaaaa-4900-0000-0000-000000000007',
                                            'aaaaaaaa-4900-0000-0000-000000000002',
                                            'aaaaaaaa-4900-0000-0000-000000000003'))
     from public.audit_logs a
    where a.actor_id in ('aaaaaaaa-4900-0000-0000-000000000001', 'aaaaaaaa-4900-0000-0000-000000000002')),
  'true:7');
select test.check('Rôles et motifs fermés à l''API',
  (has_table_privilege('authenticated', 'private.platform_admin_roles', 'select')
   or has_table_privilege('authenticated', 'private.admin_action_log', 'select'))::text, 'false');
-- Supabase refuse d'attacher un paramètre personnalisé (`xxx.yyy`) à une
-- fonction (rôle postgres non super-utilisateur) : la migration 4900 a
-- échoué ainsi au premier déploiement. Garde-fou pour toutes les fonctions.
select test.check('Aucun paramètre personnalisé attaché à une fonction',
  (select count(*)::text
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
     cross join lateral unnest(p.proconfig) as c(setting)
    where n.nspname in ('public', 'private')
      and split_part(c.setting, '=', 1) like '%.%'),
  '0');
select test.check('Permission portée par la fonction, rétablie à la sortie',
  (select count(*)::text
     from pg_proc p
     cross join lateral unnest(p.proconfig) as c(setting)
    where c.setting like 'application_name=tikeo.perm:%')
  || ':' || (current_setting('application_name') not like 'tikeo.perm:%')::text,
  '32:true');
