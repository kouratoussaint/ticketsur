-- =============================================================================
-- Tikéo — Migration 2900 : retrouver un titulaire à la porte (lot 4-3, ADR 0021)
-- =============================================================================
-- * `validate_scan` renvoie aussi le nom du titulaire d'un ticket nominatif
--   (champ facultatif du contrat v1 : les anciennes APK l'ignorent). Corps
--   recopié de la migration 2000, seule la ligne du ticket change.
-- * `door_lookup` : un contrôleur affecté à la porte, contrôle ouvert,
--   cherche un ticket par nom, téléphone ou référence (QR perdu). 10 résultats
--   au plus, téléphone masqué, 30 recherches par 10 minutes ; la recherche
--   elle-même n'est pas conservée (seulement l'heure, pour la limite).
-- * `validate_ticket_at_door` : valide le ticket choisi en passant par
--   `validate_scan` (mêmes règles : une seule entrée acceptée, en ligne,
--   idempotence par request_id). Journal `scan.manual` sans donnée.
-- =============================================================================

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

    -- 4. Contrôle ouvert par l'organisateur (« Démarrer le contrôle ») et
    --    pas encore arrêté : seul le statut compte, plus aucune fenêtre horaire.
    if v_event.status <> 'in_progress' then
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
                   then jsonb_strip_nulls(jsonb_build_object(
                          'public_reference', v_ticket.public_reference,
                          'category', v_category,
                          'holder_name', v_ticket.holder_name)) end,
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

create table public.door_lookups (
  id bigint generated always as identity primary key,
  actor_id uuid not null references public.profiles (id) on delete cascade,
  event_id uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now()
);
create index door_lookups_actor_idx on public.door_lookups (actor_id, created_at);
alter table public.door_lookups enable row level security;
revoke all on public.door_lookups from anon, authenticated;
revoke all on sequence public.door_lookups_id_seq from anon, authenticated;

-- Le contrôleur est-il affecté à cette porte, contrôle ouvert ?
create function private.can_check_at_door(p_event_id uuid, p_checkpoint_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.events e
      join public.event_assignments a on a.event_id = e.id
      join public.checkpoints cp on cp.id = p_checkpoint_id and cp.event_id = e.id and cp.active
      join public.profiles pr on pr.id = a.user_id and pr.status = 'active'
     where e.id = p_event_id
       and e.status = 'in_progress'
       and a.user_id = auth.uid()
       and a.active
       and (a.checkpoint_id is null or a.checkpoint_id = p_checkpoint_id)
       and private.has_org_role(e.organization_id,
                                array['owner','manager','controller']::public.member_role[])
  )
$$;
revoke all on function private.can_check_at_door(uuid, uuid) from public, anon, authenticated;

create function public.door_lookup(p_event_id uuid, p_checkpoint_id uuid, p_query text)
returns table (
  ticket_id uuid,
  public_reference text,
  holder_name text,
  phone_hint text,
  category text,
  is_invitation boolean,
  status public.ticket_status
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_query text := trim(coalesce(p_query, ''));
  v_folded text;
  v_digits text;
begin
  if v_actor is null or not private.can_check_at_door(p_event_id, p_checkpoint_id) then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Recherche réservée aux contrôleurs de cette porte, contrôle ouvert.';
  end if;
  if char_length(v_query) < 3 or char_length(v_query) > 60 then
    raise exception 'lookup_query_invalid'
      using errcode = '22023', detail = 'Entre 3 et 60 caractères.';
  end if;
  if (select count(*) from public.door_lookups l
       where l.actor_id = v_actor and l.created_at > now() - interval '10 minutes') >= 30 then
    raise exception 'lookup_rate_limited'
      using errcode = '54000', detail = 'Trop de recherches : réessayez dans quelques minutes.';
  end if;
  insert into public.door_lookups (actor_id, event_id) values (v_actor, p_event_id);

  v_folded := private.fold(v_query);
  v_digits := regexp_replace(v_query, '[^0-9]', '', 'g');
  return query
    select t.id, t.public_reference, t.holder_name,
           case when t.holder_phone is not null
                then '•• ' || right(regexp_replace(t.holder_phone, '[^0-9]', '', 'g'), 2) end,
           c.name, c.is_invitation, t.status
      from public.tickets t
      join public.ticket_categories c on c.id = t.category_id
     where t.event_id = p_event_id
       and (
         (t.holder_name is not null and private.fold(t.holder_name) like '%' || v_folded || '%')
         or (char_length(v_digits) >= 4 and t.holder_phone is not null
             and regexp_replace(t.holder_phone, '[^0-9]', '', 'g') like '%' || v_digits || '%')
         or upper(t.public_reference) like '%' || upper(v_query) || '%'
       )
     order by (t.status <> 'issued'), t.holder_name nulls last, t.public_reference
     limit 10;
end;
$$;
revoke all on function public.door_lookup(uuid, uuid, text) from public, anon;
grant execute on function public.door_lookup(uuid, uuid, text) to authenticated;

create function public.validate_ticket_at_door(
  p_request_id uuid,
  p_event_id uuid,
  p_checkpoint_id uuid,
  p_ticket_id uuid
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_token text;
  v_response jsonb;
  v_org uuid;
begin
  -- Sans droit sur la porte : on laisse validate_scan répondre
  -- « unauthorized » (et journaliser la tentative), sans lire de jeton.
  if private.can_check_at_door(p_event_id, p_checkpoint_id) then
    select extensions.pgp_sym_decrypt(s.token_ciphertext,
                                      private.vault_secret('ticketsur_qr_encryption_key'))
      into v_token
      from public.tickets t
      join private.ticket_secrets s on s.ticket_id = t.id
     where t.id = p_ticket_id and t.event_id = p_event_id;
  end if;
  v_response := public.validate_scan(p_request_id, p_event_id, p_checkpoint_id,
                                     coalesce(v_token, 'TS1.manuel'));
  -- Une ligne par requête (un rejeu du même request_id n'en ajoute pas).
  if v_token is not null and v_response->>'result' is not null
     and v_response->>'result' <> 'pending'
     and not exists (select 1 from public.audit_logs l
                      where l.action = 'scan.manual' and l.resource_id = p_ticket_id
                        and l.details->>'request_id' = p_request_id::text) then
    select e.organization_id into v_org from public.events e where e.id = p_event_id;
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_org, auth.uid(), 'scan.manual', 'ticket', p_ticket_id,
            jsonb_build_object('result', v_response->>'result', 'request_id', p_request_id));
  end if;
  return v_response;
end;
$$;
revoke all on function public.validate_ticket_at_door(uuid, uuid, uuid, uuid) from public, anon;
grant execute on function public.validate_ticket_at_door(uuid, uuid, uuid, uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Journal de la structure (propriétaire) : qui a fait quoi, avec l'objet
-- (référence du ticket, titre de l'événement). Les actions de l'équipe
-- Tikéo apparaissent sous « Tikéo », sans le nom de l'administrateur.
-- -----------------------------------------------------------------------------
create function public.organization_audit_logs(
  p_organization_id uuid,
  p_prefixes text[] default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  id uuid,
  created_at timestamptz,
  action text,
  resource_type text,
  actor_name text,
  by_platform boolean,
  subject text,
  details jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
     or not private.has_org_role(p_organization_id, array['owner']::public.member_role[]) then
    raise exception 'forbidden'
      using errcode = '42501', detail = 'Journal réservé au propriétaire de la structure.';
  end if;
  if p_limit is null or p_limit not between 1 and 100 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  return query
  select a.id, a.created_at, a.action, a.resource_type,
         case when a.action like 'admin.%' then null else pr.display_name end,
         a.action like 'admin.%',
         coalesce(
           case when a.resource_type = 'ticket' then
             (select t.public_reference || ' · ' || e.title
                from public.tickets t join public.events e on e.id = t.event_id
               where t.id = a.resource_id) end,
           case when a.resource_type = 'event' then
             (select e.title from public.events e where e.id = a.resource_id) end),
         -- Jamais de liste d'identifiants (export) : seulement les compteurs.
         a.details - 'ticket_ids' - 'request_id'
    from public.audit_logs a
    left join public.profiles pr on pr.id = a.actor_id
   where a.organization_id = p_organization_id
     and (p_prefixes is null
          or exists (select 1 from unnest(p_prefixes) p where a.action like p || '%'))
   order by a.created_at desc, a.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.organization_audit_logs(uuid, text[], integer, integer) from public, anon;
grant execute on function public.organization_audit_logs(uuid, text[], integer, integer) to authenticated;
