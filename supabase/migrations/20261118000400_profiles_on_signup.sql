-- =============================================================================
-- TicketSûr — Migration 0400 : profil créé à l'inscription, scan refusé
--                              proprement pour un compte sans profil actif
-- =============================================================================
-- Défaut trouvé par le test de bout en bout du 2026-11-18 (scripts/e2e-auth-api.sh) :
-- un compte fraîchement inscrit n'avait pas de ligne dans public.profiles ;
-- validate_scan échouait alors sur la clé étrangère scan_requests.actor_id
-- (HTTP 409) au lieu de répondre « unauthorized ».
-- =============================================================================

-- 1. Profil minimal à chaque nouvel utilisateur Auth -------------------------
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Utilisateur'
    ), 120)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function private.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

-- 2. Rattrapage des comptes déjà inscrits sans profil ------------------------
insert into public.profiles (id, display_name)
select u.id,
       left(coalesce(nullif(split_part(coalesce(u.email, ''), '@', 1), ''), 'Utilisateur'), 120)
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id);

-- 3. validate_scan : compte sans profil actif = « unauthorized », sans écriture,
--    réponse toujours versionnée.
create or replace function public.validate_scan(
  p_request_id uuid,
  p_event_id uuid,
  p_checkpoint_id uuid,
  p_qr_token text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_rate_limit_per_minute constant integer := 120;
  v_actor uuid := auth.uid();
  v_now timestamptz := now();
  v_request_pk uuid;
  v_stored jsonb;
  v_event public.events%rowtype;
  v_ticket public.tickets%rowtype;
  v_ticket_id uuid;
  v_category text;
  v_checkpoint_label text;
  v_result public.scan_result;
  v_validation_id uuid;
  v_first_at timestamptz;
  v_response jsonb;
begin
  -- 0. Session obligatoire et compte actif. Sans profil actif, rien n'est
  --    enregistré (le journal référence profiles).
  if v_actor is null or p_request_id is null
     or not exists (select 1 from public.profiles pr
                    where pr.id = v_actor and pr.status = 'active') then
    return jsonb_build_object('version', 1, 'request_id', p_request_id,
                              'result', 'unauthorized', 'server_time', v_now);
  end if;

  -- 1. Idempotence : la première requête (actor, request_id) gagne la ligne.
  --    Une reprise concurrente attend le commit de la première, puis relit.
  insert into public.scan_requests (actor_id, request_id, event_id, checkpoint_id, received_at)
  values (v_actor, p_request_id, p_event_id, p_checkpoint_id, v_now)
  on conflict (actor_id, request_id) do nothing
  returning id into v_request_pk;

  if v_request_pk is null then
    select sr.response into v_stored
    from public.scan_requests sr
    where sr.actor_id = v_actor and sr.request_id = p_request_id;
    return coalesce(v_stored, jsonb_build_object('request_id', p_request_id, 'result', 'pending',
                                                 'server_time', v_now));
  end if;

  <<decide>>
  begin
    -- 2. Limitation de débit par contrôleur.
    if (select count(*) from public.scan_attempts sa
        where sa.actor_id = v_actor and sa.server_time > v_now - interval '1 minute')
       >= c_rate_limit_per_minute then
      v_result := 'rate_limited';
      exit decide;
    end if;

    -- 3. Compte actif, membre actif, affectation active à l'événement et à la porte.
    select e.* into v_event from public.events e where e.id = p_event_id;
    if not found
       or not exists (
         select 1
         from public.event_assignments a
         join public.checkpoints cp on cp.id = p_checkpoint_id and cp.event_id = p_event_id and cp.active
         where a.event_id = p_event_id
           and a.user_id = v_actor
           and a.active
           and (a.checkpoint_id is null or a.checkpoint_id = p_checkpoint_id)
       )
       or not private.has_org_role(v_event.organization_id,
                                   array['owner','manager','controller']::public.member_role[]) then
      v_result := 'unauthorized';
      exit decide;
    end if;

    select cp.name into v_checkpoint_label from public.checkpoints cp where cp.id = p_checkpoint_id;

    -- 4. Événement ouvert au contrôle, à l'heure SERVEUR.
    if v_event.status not in ('published', 'in_progress')
       or v_now < v_event.starts_at - v_event.scan_opens_before
       or v_now > v_event.ends_at + v_event.scan_closes_after then
      v_result := 'event_inactive';
      exit decide;
    end if;

    -- 5. Format du jeton puis recherche par HMAC (jamais en clair).
    if p_qr_token is null or p_qr_token !~ '^TS1\.[A-Za-z0-9_-]{43}$' then
      v_result := 'not_found';
      exit decide;
    end if;

    select s.ticket_id into v_ticket_id
    from private.ticket_secrets s
    where s.token_hmac = private.token_hmac(p_qr_token);
    if v_ticket_id is null then
      v_result := 'not_found';
      exit decide;
    end if;

    select t.* into v_ticket from public.tickets t where t.id = v_ticket_id;
    if v_ticket.event_id <> p_event_id then
      v_ticket_id := null; -- ne rien révéler du billet d'un autre événement
      v_result := 'wrong_event';
      exit decide;
    end if;

    -- 6. Consommation atomique : un seul UPDATE peut réussir.
    update public.tickets t
       set status = 'redeemed',
           redeemed_at = v_now,
           redeemed_by = v_actor,
           redeemed_checkpoint_id = p_checkpoint_id
     where t.id = v_ticket_id
       and t.status = 'issued'
       and (t.expires_at is null or t.expires_at > v_now)
    returning t.redeemed_at into v_first_at;

    if found then
      v_result := 'accepted';
      exit decide;
    end if;

    -- 7. Échec de l'UPDATE : on relit l'état COMMITÉ pour qualifier le refus.
    select t.* into v_ticket from public.tickets t where t.id = v_ticket_id;
    v_result := case
      when v_ticket.status = 'redeemed' then 'already_used'
      when v_ticket.status = 'revoked' then 'revoked'
      else 'expired'
    end::public.scan_result;
    if v_result = 'already_used' then
      v_first_at := v_ticket.redeemed_at;
      select cp.name into v_checkpoint_label
      from public.checkpoints cp where cp.id = v_ticket.redeemed_checkpoint_id;
    end if;
  end decide;

  -- 8. Journal de la tentative (append-only) et réponse versionnée.
  insert into public.scan_attempts (scan_request_id, ticket_id, actor_id, event_id, checkpoint_id, outcome, server_time)
  values (v_request_pk, v_ticket_id, v_actor, p_event_id, p_checkpoint_id, v_result, v_now)
  returning id into v_validation_id;

  if v_ticket_id is not null then
    select tc.name into v_category from public.ticket_categories tc where tc.id = v_ticket.category_id;
  end if;

  v_response := jsonb_strip_nulls(jsonb_build_object(
    'version', 1,
    'request_id', p_request_id,
    'result', v_result,
    'validation_id', case when v_result = 'accepted' then v_validation_id end,
    'ticket', case when v_result in ('accepted', 'already_used', 'revoked', 'expired')
                   then jsonb_build_object('public_reference', v_ticket.public_reference,
                                           'category', v_category) end,
    'first_validated_at', case when v_result in ('accepted', 'already_used') then v_first_at end,
    'checkpoint_label', case when v_result in ('accepted', 'already_used') then v_checkpoint_label end,
    'server_time', v_now
  ));

  update public.scan_requests sr
     set result_code = v_result, ticket_id = v_ticket_id, response = v_response
   where sr.id = v_request_pk;

  return v_response;
end;
$$;
revoke all on function public.validate_scan(uuid, uuid, uuid, text) from public, anon;
grant execute on function public.validate_scan(uuid, uuid, uuid, text) to authenticated;
