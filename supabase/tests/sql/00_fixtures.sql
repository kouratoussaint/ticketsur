-- =============================================================================
-- TicketSûr — Données de test (NON SENSIBLES, jamais en production)
-- =============================================================================
-- Deux organisations isolées, des événements dans divers états, des contrôleurs
-- affectés / non affectés / désactivés et 50 contrôleurs pour la charge.
-- =============================================================================
\set ON_ERROR_STOP 1

-- Les clés Vault sont créées par la migration 0300 (générées côté serveur).

-- Packs (migration 3600) : les tests jouent sans limite, quel que soit le
-- réglage du pack Découverte sur le projet (transaction annulée sur le staging).
delete from public.billing_pack_options
 where pack_id = (select id from public.billing_packs where code = 'decouverte');

-- Outils de test --------------------------------------------------------------
create schema test;
grant usage on schema test to authenticated;

create table test.tokens (label text primary key, ticket_id uuid not null, token text not null);
grant select on test.tokens to authenticated;

create or replace function test.login(p_user uuid)
returns void language sql as $$
  select set_config('request.jwt.claims',
    case when p_user is null then '' else
      json_build_object('sub', p_user, 'role', 'authenticated')::text end, false);
  select null::void;
$$;
grant execute on function test.login(uuid) to authenticated;

create or replace function test.tok(p_label text)
returns text language sql stable as $$ select token from test.tokens where label = p_label $$;
grant execute on function test.tok(text) to authenticated;

create or replace function test.check(p_label text, p_actual text, p_expected text)
returns text language plpgsql as $$
begin
  if p_actual is distinct from p_expected then
    raise exception 'ÉCHEC  % : attendu « % », obtenu « % »', p_label, p_expected, p_actual;
  end if;
  return 'OK    ' || p_label;
end $$;
grant execute on function test.check(text, text, text) to authenticated;

-- Complète un événement (ville + photo déposée) pour pouvoir le publier
-- (migration 1100). Réservé aux tests : écrit directement, sans contrôle.
create or replace function test.complete_event(p_event uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_path text;
begin
  select e.organization_id || '/' || e.id || '/couverture-test.jpg' into v_path
  from public.events e where e.id = p_event;
  insert into storage.objects (bucket_id, name) values ('event-covers', v_path)
  on conflict do nothing;
  update public.events set city = coalesce(city, 'Ouagadougou'), cover_path = v_path
  where id = p_event;
end $$;
grant execute on function test.complete_event(uuid) to authenticated;

-- Supprime un objet Storage avec les droits de l'appelant (RLS) et renvoie
-- le nombre de lignes supprimées. Sur un vrai projet Supabase, la
-- suppression SQL directe est interdite (Storage API seule) : la fonction
-- renvoie alors « api ».
create or replace function test.delete_object(p_name text)
returns text language plpgsql as $$
declare
  v_count integer;
begin
  with d as (delete from storage.objects where name = p_name returning 1)
  select count(*) into v_count from d;
  return v_count::text;
exception when others then
  if sqlerrm like 'Direct deletion from storage tables is not allowed%' then
    return 'api';
  end if;
  raise;
end $$;
grant execute on function test.delete_object(text) to authenticated;

-- Vérifie un nombre de suppressions, sauf si Supabase interdit la
-- suppression SQL directe (la règle RLS reste alors celle testée en local).
create or replace function test.check_delete(p_label text, p_actual text, p_expected text)
returns text language sql as $$
  select case when p_actual = 'api'
    then 'OK    ' || p_label || ' (suppression SQL directe interdite par Supabase : non rejouable ici)'
    else test.check(p_label, p_actual, p_expected) end
$$;
grant execute on function test.check_delete(text, text, text) to authenticated;

-- Identités -------------------------------------------------------------------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'owner.a@test.local'),
  ('11111111-0000-0000-0000-000000000001', 'ctrl.a1@test.local'),
  ('11111111-0000-0000-0000-000000000002', 'ctrl.a2@test.local'),
  ('11111111-0000-0000-0000-000000000003', 'ctrl.disabled@test.local'),
  ('11111111-0000-0000-0000-000000000004', 'ctrl.unassigned@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'owner.b@test.local'),
  ('22222222-0000-0000-0000-000000000001', 'ctrl.b@test.local');
insert into auth.users (id, email)
select format('33333333-0000-0000-0000-%s', lpad(i::text, 12, '0'))::uuid, format('load%s@test.local', i)
from generate_series(1, 50) i;

-- Les profils sont créés par le déclencheur on_auth_user_created (migration 0400).
select test.check('Profil créé automatiquement pour chaque compte',
  (select count(*) from auth.users u where not exists (select 1 from public.profiles p where p.id = u.id))::text, '0');

insert into public.organizations (id, name, slug, owner_id) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Organisation A', 'org-a', '11111111-1111-1111-1111-111111111111'),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'Organisation B', 'org-b', '22222222-2222-2222-2222-222222222222');

insert into public.organization_members (organization_id, user_id, role, active) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'owner', true),
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'controller', true),
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002', 'controller', true),
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000003', 'controller', true),
  ('aaaaaaaa-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000004', 'controller', true),
  ('bbbbbbbb-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'owner', true),
  ('bbbbbbbb-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'controller', true);
insert into public.organization_members (organization_id, user_id, role)
select 'aaaaaaaa-0000-0000-0000-000000000001', id, 'controller'
from auth.users where email like 'load%';

-- Événements : A1 en cours, A2 en cours (autre événement), A3 clôturé, B1 en cours.
insert into public.events (id, organization_id, title, starts_at, ends_at, status) values
  ('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-000000000001', 'Concert A1', now() - interval '1 hour', now() + interval '3 hours', 'in_progress'),
  ('aaaaaaaa-0000-0000-0000-0000000000e2', 'aaaaaaaa-0000-0000-0000-000000000001', 'Gala A2',    now() - interval '1 hour', now() + interval '3 hours', 'published'),
  ('aaaaaaaa-0000-0000-0000-0000000000e3', 'aaaaaaaa-0000-0000-0000-000000000001', 'Forum A3',   now() - interval '1 hour', now() + interval '3 hours', 'closed'),
  ('bbbbbbbb-0000-0000-0000-0000000000e1', 'bbbbbbbb-0000-0000-0000-000000000001', 'Festival B1', now() - interval '1 hour', now() + interval '3 hours', 'in_progress');

insert into public.ticket_categories (id, event_id, name, capacity) values
  ('aaaaaaaa-0000-0000-0000-0000000000f1', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Standard', null),
  ('aaaaaaaa-0000-0000-0000-0000000000f2', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'VIP', 2),
  ('aaaaaaaa-0000-0000-0000-0000000000f3', 'aaaaaaaa-0000-0000-0000-0000000000e2', 'Standard', null),
  ('aaaaaaaa-0000-0000-0000-0000000000f4', 'aaaaaaaa-0000-0000-0000-0000000000e3', 'Standard', null),
  ('aaaaaaaa-0000-0000-0000-0000000000f5', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Charge', null),
  ('bbbbbbbb-0000-0000-0000-0000000000f1', 'bbbbbbbb-0000-0000-0000-0000000000e1', 'Standard', null);

insert into public.checkpoints (id, event_id, name) values
  ('aaaaaaaa-0000-0000-0000-0000000000c1', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Entrée principale'),
  ('aaaaaaaa-0000-0000-0000-0000000000c2', 'aaaaaaaa-0000-0000-0000-0000000000e1', 'Entrée VIP'),
  ('aaaaaaaa-0000-0000-0000-0000000000c3', 'aaaaaaaa-0000-0000-0000-0000000000e2', 'Entrée'),
  ('aaaaaaaa-0000-0000-0000-0000000000c4', 'aaaaaaaa-0000-0000-0000-0000000000e3', 'Entrée'),
  ('bbbbbbbb-0000-0000-0000-0000000000c1', 'bbbbbbbb-0000-0000-0000-0000000000e1', 'Entrée');

-- Affectations : a1 à la porte principale ; a2 à toutes les portes de A1 ;
-- « disabled » affecté puis désactivé dans les tests ; « unassigned » sans affectation.
insert into public.event_assignments (event_id, user_id, checkpoint_id) values
  ('aaaaaaaa-0000-0000-0000-0000000000e1', '11111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-0000000000c1'),
  ('aaaaaaaa-0000-0000-0000-0000000000e1', '11111111-0000-0000-0000-000000000002', null),
  ('aaaaaaaa-0000-0000-0000-0000000000e1', '11111111-0000-0000-0000-000000000003', null),
  ('aaaaaaaa-0000-0000-0000-0000000000e3', '11111111-0000-0000-0000-000000000001', null),
  ('bbbbbbbb-0000-0000-0000-0000000000e1', '22222222-0000-0000-0000-000000000001', null);
insert into public.event_assignments (event_id, user_id, checkpoint_id)
select 'aaaaaaaa-0000-0000-0000-0000000000e1', id, null from auth.users where email like 'load%';

-- Émission réelle via la fonction publique, en tant que propriétaire. -----------
select test.login('11111111-1111-1111-1111-111111111111');
insert into test.tokens
select 'a1_' || lpad((row_number() over ())::text, 3, '0'), ticket_id, qr_token
from public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f1', 40);
insert into test.tokens
select 'a2_' || lpad((row_number() over ())::text, 3, '0'), ticket_id, qr_token
from public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e2', 'aaaaaaaa-0000-0000-0000-0000000000f3', 5);
select test.login('22222222-2222-2222-2222-222222222222');
insert into test.tokens
select 'b1_' || lpad((row_number() over ())::text, 3, '0'), ticket_id, qr_token
from public.issue_tickets('bbbbbbbb-0000-0000-0000-0000000000e1', 'bbbbbbbb-0000-0000-0000-0000000000f1', 5);
select test.login(null);

-- Le billet A3 (événement clôturé) est créé directement : l'émission y est interdite.
with t as (
  insert into public.tickets (event_id, category_id, public_reference)
  values ('aaaaaaaa-0000-0000-0000-0000000000e3', 'aaaaaaaa-0000-0000-0000-0000000000f4', 'TS-AAAA-3333')
  returning id
), k as (select private.new_qr_token() as token)
insert into test.tokens select 'a3_001', t.id, k.token from t, k;
insert into private.ticket_secrets (ticket_id, token_hmac, token_ciphertext)
select ticket_id, private.token_hmac(token), extensions.pgp_sym_encrypt(token, 'x') from test.tokens where label = 'a3_001';

-- Un billet expiré.
update public.tickets set expires_at = now() - interval '1 minute'
where id = (select ticket_id from test.tokens where label = 'a1_040');
