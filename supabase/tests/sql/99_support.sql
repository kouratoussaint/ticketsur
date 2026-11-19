-- =============================================================================
-- Tikéo — Tests : support et annonces (migration 2300)
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

reset role;
insert into auth.users (id, email) values
  ('aaaaaaaa-2300-0000-0000-000000000001', 'admin-support@test.local'),
  ('aaaaaaaa-2300-0000-0000-000000000002', 'promoteur-support@test.local'),
  ('aaaaaaaa-2300-0000-0000-000000000003', 'curieux-support@test.local'),
  ('aaaaaaaa-2300-0000-0000-000000000004', 'controleur-support@test.local');
update public.profiles set is_platform_admin = true
 where id = 'aaaaaaaa-2300-0000-0000-000000000001';

set role authenticated;
select test.login('aaaaaaaa-2300-0000-0000-000000000002');
select (public.create_organization('Studio Support Qxw')::jsonb)->>'id' as org \gset
reset role;
insert into public.organization_members (organization_id, user_id, role)
values (:'org', 'aaaaaaaa-2300-0000-0000-000000000004', 'controller');
set role authenticated;

-- Demande d'un promoteur -----------------------------------------------------------
select test.login('aaaaaaaa-2300-0000-0000-000000000002');
select public.create_support_request('Scan refusé à la porte', 'problem',
  'Mes contrôleurs voient « Contrôle indisponible ».', :'org') as req \gset
reset role;
select test.check('Demande ouverte, rattachée à la structure',
  (select status || '|' || category || '|' || (organization_id = :'org')
   from public.support_requests where id = :'req'),
  'open|problem|true');
set role authenticated;
select test.check('Mes demandes : une, pas de réponse non lue',
  (select count(*) || '|' || bool_or(unread) from public.my_support_requests()),
  '1|false');
do $$
begin
  begin
    perform public.create_support_request('ab', 'problem', 'x');
    raise exception 'ÉCHEC  sujet trop court accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Sujet trop court refusé';
  end;
end $$;

-- Un autre compte ne voit ni ne répond.
select test.login('aaaaaaaa-2300-0000-0000-000000000003');
do $$
begin
  begin
    perform 1 from public.support_thread(
      (select id from public.support_requests where subject = 'Scan refusé à la porte'));
    raise exception 'ÉCHEC  demande lue par un autre compte';
  exception when insufficient_privilege then
    raise notice 'OK    Demande invisible des autres comptes';
  end;
  begin
    perform public.admin_support_requests();
    raise exception 'ÉCHEC  console du support ouverte';
  exception when insufficient_privilege then
    raise notice 'OK    Console du support réservée aux administrateurs';
  end;
end $$;

-- L'administrateur la voit, la lit et répond.
select test.login('aaaaaaaa-2300-0000-0000-000000000001');
select test.check('Console : non lue, demandeur et structure',
  (select unread || '|' || requester_email || '|' || organization_name || '|' || messages
   from public.admin_support_requests(null, 'scan refuse')),
  'true|promoteur-support@test.local|Studio Support Qxw|1');
select count(*) from public.support_thread(:'req') \gset ignored_
reset role;
select test.check('Lue par l''administrateur',
  (select admin_unread::text from public.support_requests where id = :'req'), 'false');
set role authenticated;
select test.check('Réponse : demande « répondue »',
  public.reply_support_request(:'req', 'Démarrez le contrôle depuis la fiche de l''événement.'),
  'answered');
select test.check('Réponse journalisée sans contenu',
  (select details::text from public.admin_audit_logs('admin.support_replied', 100)
   where resource_id = :'req'), '{}');

-- Le promoteur voit la réponse signée « Support Tikéo » et relance.
select test.login('aaaaaaaa-2300-0000-0000-000000000002');
select test.check('Réponse non lue côté promoteur',
  (select unread::text from public.my_support_requests() where id = :'req'), 'true');
select test.check('Fil : signature « Support Tikéo »',
  (select string_agg(t.from_admin || ':' || t.author_name, ',' order by t.n)
   from public.support_thread(:'req')
        with ordinality as t(id, from_admin, author_name, body, created_at, n)),
  'false:promoteur-support,true:Support Tikéo');
select test.check('Fil lu',
  (select unread::text from public.my_support_requests() where id = :'req'), 'false');
select test.check('Relance : demande rouverte',
  public.reply_support_request(:'req', 'Merci, c''est réglé.'), 'open');
select public.close_support_request(:'req') \gset ignored_
select test.check('Fermée par le promoteur',
  (select status from public.my_support_requests() where id = :'req'), 'closed');

-- Limite : 5 demandes en cours.
do $$
begin
  for i in 1..5 loop
    perform public.create_support_request('Question numéro ' || i, 'question', 'Bonjour');
  end loop;
  begin
    perform public.create_support_request('Sixième question', 'question', 'Bonjour');
    raise exception 'ÉCHEC  sixième demande en cours acceptée';
  exception when program_limit_exceeded then
    raise notice 'OK    5 demandes en cours au plus';
  end;
end $$;

-- Annonces ----------------------------------------------------------------------
select test.login('aaaaaaaa-2300-0000-0000-000000000001');
do $$
begin
  begin
    perform public.admin_publish_announcement('Titre', 'Corps', array[]::text[]);
    raise exception 'ÉCHEC  annonce sans destinataire';
  exception when invalid_parameter_value then
    raise notice 'OK    Annonce : au moins un destinataire';
  end;
  begin
    perform public.admin_publish_announcement('Titre', 'Corps', array['tout_le_monde']);
    raise exception 'ÉCHEC  destinataire inconnu accepté';
  exception when invalid_parameter_value then
    raise notice 'OK    Annonce : destinataires connus seulement';
  end;
end $$;
select public.admin_publish_announcement('Maintenance Qxw ce soir', 'Coupure de 22 h à 23 h.',
  array['promoters', 'controllers'], 'important', now() + interval '1 day') as a1 \gset
select public.admin_publish_announcement('Bienvenue Qxw', 'Découvrez les événements.',
  array['visitors', 'users']) as a2 \gset
select test.check('Publication journalisée : destinataires, sans texte',
  (select details::text from public.admin_audit_logs('admin.announcement_published', 100)
   where resource_id = :'a1'),
  '{"level": "important", "audiences": ["controllers", "promoters"]}');

select test.login('aaaaaaaa-2300-0000-0000-000000000002');
select test.check('Promoteur : la maintenance seulement',
  (select string_agg(title, ',') from public.my_announcements() where title like '%Qxw%'),
  'Maintenance Qxw ce soir');
select test.login('aaaaaaaa-2300-0000-0000-000000000004');
select test.check('Contrôleur : la maintenance seulement',
  (select string_agg(title, ',') from public.my_announcements() where title like '%Qxw%'),
  'Maintenance Qxw ce soir');
select test.login('aaaaaaaa-2300-0000-0000-000000000003');
select test.check('Compte classique : le message de bienvenue',
  (select string_agg(title, ',') from public.my_announcements() where title like '%Qxw%'),
  'Bienvenue Qxw');
reset role;
select test.login(null);
set role anon;
select coalesce(string_agg(title, ','), '∅') as anon_ann
  from public.my_announcements() where title like '%Qxw%' \gset
reset role;
select test.check('Visiteur sans compte : le message de bienvenue', :'anon_ann', 'Bienvenue Qxw');

set role authenticated;
select test.login('aaaaaaaa-2300-0000-0000-000000000001');
select public.admin_archive_announcement(:'a1') \gset ignored_
select test.check('Console : annonce archivée, plus active',
  (select active::text from public.admin_announcements() where id = :'a1'), 'false');
select test.login('aaaaaaaa-2300-0000-0000-000000000002');
select test.check('Annonce archivée : plus affichée',
  (select count(*)::text from public.my_announcements() where title like '%Qxw%'), '0');
reset role;
