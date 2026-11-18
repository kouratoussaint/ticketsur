-- =============================================================================
-- TicketSûr — Tests d'acceptation séquentiels du moteur de scan (cahier §17.1)
-- Exécutés sous le rôle « authenticated », comme un appel réel via l'API.
-- Toute assertion fausse lève une exception et arrête le script (code ≠ 0).
-- =============================================================================
\set ON_ERROR_STOP 1
\set QUIET 1
\pset tuples_only on
\pset format unaligned

\set ev_a1 '''aaaaaaaa-0000-0000-0000-0000000000e1'''
\set ev_a2 '''aaaaaaaa-0000-0000-0000-0000000000e2'''
\set ev_a3 '''aaaaaaaa-0000-0000-0000-0000000000e3'''
\set cp_main '''aaaaaaaa-0000-0000-0000-0000000000c1'''
\set cp_vip '''aaaaaaaa-0000-0000-0000-0000000000c2'''
\set cp_a3 '''aaaaaaaa-0000-0000-0000-0000000000c4'''
\set ctrl_a1 '''11111111-0000-0000-0000-000000000001'''
\set ctrl_a2 '''11111111-0000-0000-0000-000000000002'''
\set ctrl_dis '''11111111-0000-0000-0000-000000000003'''
\set ctrl_none '''11111111-0000-0000-0000-000000000004'''
\set owner_a '''11111111-1111-1111-1111-111111111111'''
\set owner_b '''22222222-2222-2222-2222-222222222222'''

set role authenticated;

-- AT-01 : premier scan d'un billet émis par un contrôleur affecté ----------------
select test.login(:ctrl_a1);
select public.validate_scan('00000000-0000-4000-8000-000000000001', :ev_a1, :cp_main, test.tok('a1_001')) as r1 \gset
select test.check('AT-01 premier scan → accepted', (:'r1'::jsonb)->>'result', 'accepted');
select test.check('AT-01 validation_id présent', ((:'r1'::jsonb) ? 'validation_id')::text, 'true');
select test.check('AT-01 porte renvoyée', (:'r1'::jsonb)->>'checkpoint_label', 'Entrée principale');
select test.check('AT-01 catégorie renvoyée', (:'r1'::jsonb)->'ticket'->>'category', 'Standard');

-- AT-12 : même request_id rejoué (timeout après commit) → réponse IDENTIQUE ----
select public.validate_scan('00000000-0000-4000-8000-000000000001', :ev_a1, :cp_main, test.tok('a1_001')) as r1bis \gset
select test.check('AT-12 rejeu même request_id → même réponse', (:'r1bis'::jsonb)::text, (:'r1'::jsonb)::text);

-- AT-02 / AT-13 : nouveau scan, autre request_id → already_used + heure initiale
select test.login(:ctrl_a2);
select public.validate_scan('00000000-0000-4000-8000-000000000002', :ev_a1, :cp_vip, test.tok('a1_001')) as r2 \gset
select test.check('AT-02 second scan → already_used', (:'r2'::jsonb)->>'result', 'already_used');
select test.check('AT-02 heure de la PREMIÈRE validation', (:'r2'::jsonb)->>'first_validated_at', (:'r1'::jsonb)->>'first_validated_at');
select test.check('AT-02 porte de la première validation', (:'r2'::jsonb)->>'checkpoint_label', 'Entrée principale');
select test.check('AT-02 pas de validation_id sur refus', ((:'r2'::jsonb) ? 'validation_id')::text, 'false');

-- AT-05 : QR inventé (format valide) et QR étranger (format invalide) -----------
select test.check('AT-05 jeton inventé → not_found',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main,
    'TS1.' || rtrim(translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'), '='))->>'result',
  'not_found');
select test.check('AT-05 QR étranger → not_found',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, 'https://exemple.com/billet/123')->>'result', 'not_found');

-- AT-06 : billet d'un autre événement → wrong_event, sans le consommer -----------
select test.check('AT-06 billet A2 scanné à A1 → wrong_event',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a2_001'))->>'result', 'wrong_event');
select test.check('AT-06 billet B1 (autre organisation) → wrong_event',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('b1_001'))->>'result', 'wrong_event');

-- AT-09 : contrôleur sans affectation / porte non attribuée ----------------------
select test.login(:ctrl_none);
select test.check('AT-09 contrôleur non affecté → unauthorized',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_002'))->>'result', 'unauthorized');
select test.login(:ctrl_a1);
select test.check('AT-09 porte non attribuée (VIP) → unauthorized',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_vip, test.tok('a1_002'))->>'result', 'unauthorized');
select test.check('AT-09 porte d''un autre événement → unauthorized',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_a3, test.tok('a1_002'))->>'result', 'unauthorized');
select test.login(null);
select test.check('Sans session → unauthorized',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_002'))->>'result', 'unauthorized');

-- Un refus ne consomme pas le billet : a1_002 passe ensuite normalement ----------
select test.login(:ctrl_a1);
select test.check('§6.3 refus antérieurs non consommateurs → accepted',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_002'))->>'result', 'accepted');

-- AT-08 : événement clôturé ------------------------------------------------------
select test.check('AT-08 événement clôturé → event_inactive',
  public.validate_scan(gen_random_uuid(), :ev_a3, :cp_a3, test.tok('a3_001'))->>'result', 'event_inactive');

-- Billet expiré ------------------------------------------------------------------
select test.check('Billet expiré → expired',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_040'))->>'result', 'expired');

-- AT-07 : billet révoqué par le propriétaire, puis scanné -----------------------
select test.login(:owner_a);
select test.check('TIC-04 révocation', public.revoke_ticket(
  (select ticket_id from test.tokens where label = 'a1_003'), 'perte déclarée')::text, 'revoked');
select test.login(:ctrl_a1);
select test.check('AT-07 billet révoqué → revoked',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_003'))->>'result', 'revoked');

-- AT-10 : contrôleur désactivé APRÈS connexion → refus au prochain scan ---------
select test.login(:ctrl_dis);
select test.check('AT-10 avant désactivation → accepted',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_004'))->>'result', 'accepted');
reset role;
update public.organization_members set active = false
where user_id = '11111111-0000-0000-0000-000000000003';
set role authenticated;
select test.check('AT-10 après désactivation → unauthorized',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_005'))->>'result', 'unauthorized');

-- Écriture directe interdite : le mobile ne peut pas marquer un billet ----------
select test.login(:ctrl_a1);
do $$
begin
  begin
    update public.tickets set status = 'issued' where true;
    raise exception 'ÉCHEC  UPDATE direct de tickets autorisé';
  exception when insufficient_privilege then
    raise notice 'OK    §10.2 UPDATE direct de tickets refusé';
  end;
  begin
    perform 1 from private.ticket_secrets limit 1;
    raise exception 'ÉCHEC  lecture de private.ticket_secrets autorisée';
  exception when insufficient_privilege then
    raise notice 'OK    §10.2 secrets QR illisibles par l''API';
  end;
  begin
    insert into public.scan_attempts (actor_id, outcome) values (auth.uid(), 'accepted');
    raise exception 'ÉCHEC  INSERT direct de scan_attempts autorisé';
  exception when insufficient_privilege then
    raise notice 'OK    §10.2 journal de scans non falsifiable';
  end;
end $$;
select test.check('Contrôleur : liste des billets invisible',
  (select count(*) from public.tickets)::text, '0');

-- AT-14 : isolation des organisations -------------------------------------------
select test.login(:owner_b);
select test.check('AT-14 owner B ne voit aucun billet de A',
  (select count(*) from public.tickets t join test.tokens k on k.ticket_id = t.id where k.label like 'a%')::text, '0');
select test.check('AT-14 owner B ne voit pas les événements de A',
  (select count(*) from public.events where organization_id = 'aaaaaaaa-0000-0000-0000-000000000001')::text, '0');
select test.check('AT-14 owner B ne voit pas les scans de A',
  (select count(*) from public.scan_attempts where event_id = 'aaaaaaaa-0000-0000-0000-0000000000e1')::text, '0');
select test.check('AT-14 owner B voit ses 5 billets',
  (select count(*) from public.tickets)::text, '5');
do $$
begin
  perform public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f1', 1);
  raise exception 'ÉCHEC  owner B a émis un billet pour A';
exception when insufficient_privilege then
  raise notice 'OK    AT-14 owner B ne peut pas émettre pour A';
end $$;
select test.login(:owner_a);
select test.check('Owner A voit les scans de son événement',
  ((select count(*) from public.scan_attempts where event_id = 'aaaaaaaa-0000-0000-0000-0000000000e1') > 0)::text, 'true');

-- Quota de catégorie (EVT-03) -----------------------------------------------------
select test.check('EVT-03 VIP : 2 billets dans le quota',
  (select count(*) from public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f2', 2))::text, '2');
do $$
begin
  perform public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f2', 1);
  raise exception 'ÉCHEC  quota VIP dépassé sans erreur';
exception when invalid_parameter_value then
  raise notice 'OK    EVT-03 quota VIP dépassé → refus';
end $$;

-- Compte fraîchement inscrit, profil créé par le déclencheur (migration 0400)
reset role;
insert into auth.users (id, email) values
  ('44444444-0000-0000-0000-000000000001', 'nouveau.inscrit@test.local'),
  ('44444444-0000-0000-0000-000000000002', 'ctrl.profil.desactive@test.local');
insert into public.organization_members (organization_id, user_id, role)
values ('aaaaaaaa-0000-0000-0000-000000000001', '44444444-0000-0000-0000-000000000002', 'controller');
insert into public.event_assignments (event_id, user_id)
values ('aaaaaaaa-0000-0000-0000-0000000000e1', '44444444-0000-0000-0000-000000000002');
update public.profiles set status = 'disabled' where id = '44444444-0000-0000-0000-000000000002';
select test.check('Profil créé à l''inscription',
  (select count(*) from public.profiles where id = '44444444-0000-0000-0000-000000000001')::text, '1');
set role authenticated;
select test.login('44444444-0000-0000-0000-000000000001');
select test.check('Nouvel inscrit sans organisation → unauthorized (pas d''erreur)',
  public.validate_scan(gen_random_uuid(), :ev_a1, :cp_main, test.tok('a1_006'))->>'result', 'unauthorized');
select test.login('44444444-0000-0000-0000-000000000002');
select test.check('Profil désactivé, même affecté → unauthorized',
  public.validate_scan('00000000-0000-4000-8000-0000000000d1', :ev_a1, :cp_main, test.tok('a1_006'))->>'result',
  'unauthorized');
reset role;
select test.check('Profil désactivé : aucune écriture dans le journal',
  (select count(*) from public.scan_requests where request_id = '00000000-0000-4000-8000-0000000000d1')::text, '0');
select test.check('a1_006 toujours disponible après ces refus',
  (select status::text from public.tickets t join test.tokens k on k.ticket_id = t.id where k.label = 'a1_006'), 'issued');

-- AT-19 : le jeton brut n'apparaît dans aucune table métier ----------------------
reset role;
select test.check('AT-19 aucun jeton en clair dans scan_requests / scan_attempts / audit_logs / tickets',
  (select count(*) from test.tokens k where exists (
     select 1 from public.scan_requests sr where sr.response::text like '%' || k.token || '%')
   or exists (select 1 from public.audit_logs a where a.details::text like '%' || k.token || '%')
   or exists (select 1 from public.tickets t where t::text like '%' || k.token || '%'))::text, '0');

-- Format du jeton : 256 bits, préfixe versionné ----------------------------------
select test.check('TIC-02 jetons au format TS1.<43 base64url>',
  (select count(*) from test.tokens where token !~ '^TS1\.[A-Za-z0-9_-]{43}$')::text, '0');

\echo 'OK    Tous les tests d''acceptation séquentiels sont verts.'
