-- =============================================================================
-- TicketSûr — Migration 0200 : émission/révocation des billets et validation
--                              atomique des scans (cahier §7)
-- =============================================================================
-- Invariant non négociable : pour tout billet à usage unique, au plus UNE
-- validation « accepted » est enregistrée, quel que soit le nombre d'appels
-- simultanés. Il repose sur :
--   1. UPDATE conditionnel « status = 'issued' » (verrou de ligne + réévaluation
--      du WHERE sous READ COMMITTED) ;
--   2. l'index unique partiel scan_attempts_one_accept_per_ticket (filet) ;
--   3. l'unicité (actor_id, request_id) pour l'idempotence des reprises.
--
-- Secrets requis dans Supabase Vault (jamais dans le dépôt) :
--   ticketsur_qr_hmac_key       : poivre HMAC des jetons (≥ 32 octets aléatoires)
--   ticketsur_qr_encryption_key : clé de chiffrement des copies de jetons
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Accès aux secrets Vault
-- -----------------------------------------------------------------------------
create or replace function private.vault_secret(p_name text)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_secret text;
begin
  select ds.decrypted_secret into v_secret
  from vault.decrypted_secrets ds
  where ds.name = p_name;
  if v_secret is null or char_length(v_secret) < 32 then
    raise exception 'Secret Vault manquant ou trop court : %', p_name
      using errcode = 'TS001';
  end if;
  return v_secret;
end;
$$;
revoke all on function private.vault_secret(text) from public, anon, authenticated;

create or replace function private.token_hmac(p_token text)
returns bytea
language sql
stable
security definer
set search_path = ''
as $$
  select extensions.hmac(
    convert_to(p_token, 'UTF8'),
    convert_to(private.vault_secret('ticketsur_qr_hmac_key'), 'UTF8'),
    'sha256'
  )
$$;
revoke all on function private.token_hmac(text) from public, anon, authenticated;

-- Jeton : « TS1. » + 43 caractères base64url = 256 bits issus de gen_random_bytes.
create or replace function private.new_qr_token()
returns text
language sql
volatile
set search_path = ''
as $$
  select 'TS1.' || rtrim(translate(encode(extensions.gen_random_bytes(32), 'base64'), '+/', '-_'), '=')
$$;
revoke all on function private.new_qr_token() from public, anon, authenticated;

-- Référence publique imprimée : aléatoire (40 bits), alphabet sans 0/O/1/I.
create or replace function private.new_public_reference()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  v_bytes bytea := extensions.gen_random_bytes(8);
  v_out text := '';
begin
  for i in 0..7 loop
    v_out := v_out || substr(v_alphabet, (get_byte(v_bytes, i) % 32) + 1, 1);
  end loop;
  return 'TS-' || substr(v_out, 1, 4) || '-' || substr(v_out, 5, 4);
end;
$$;
revoke all on function private.new_public_reference() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Émission de billets (unitaire ou lot) — renvoie les jetons UNE fois
-- -----------------------------------------------------------------------------
create or replace function public.issue_tickets(
  p_event_id uuid,
  p_category_id uuid,
  p_quantity integer
)
returns table (ticket_id uuid, public_reference text, qr_token text)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
  v_existing integer;
  v_token text;
  v_ticket_id uuid;
  v_reference text;
  v_hmac_key text := private.vault_secret('ticketsur_qr_hmac_key');
  v_enc_key text := private.vault_secret('ticketsur_qr_encryption_key');
begin
  if v_actor is null then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 5000 then
    raise exception 'Quantité hors limites (1 à 5000 par lot)' using errcode = '22023';
  end if;

  select * into v_event from public.events e where e.id = p_event_id;
  if not found
     or not private.has_org_role(v_event.organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'Événement introuvable ou droits insuffisants' using errcode = '42501';
  end if;
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'Événement fermé : émission impossible' using errcode = '22023';
  end if;

  -- Verrou de la catégorie : sérialise les émissions concurrentes (quota exact).
  select * into v_category from public.ticket_categories c
  where c.id = p_category_id and c.event_id = p_event_id
  for update;
  if not found then
    raise exception 'Catégorie inconnue pour cet événement' using errcode = '22023';
  end if;

  select count(*) into v_existing from public.tickets t
  where t.category_id = p_category_id and t.status <> 'revoked';
  if v_category.capacity is not null and v_existing + p_quantity > v_category.capacity then
    raise exception 'Quota de la catégorie dépassé (% restants)', v_category.capacity - v_existing
      using errcode = '22023';
  end if;

  for i in 1..p_quantity loop
    v_token := private.new_qr_token();
    loop
      v_reference := private.new_public_reference();
      begin
        insert into public.tickets (event_id, category_id, public_reference, issued_by)
        values (p_event_id, p_category_id, v_reference, v_actor)
        returning id into v_ticket_id;
        exit;
      exception when unique_violation then
        -- Collision de référence publique (~1e-5 pour 10 000 billets) : on retire.
        null;
      end;
    end loop;

    insert into private.ticket_secrets (ticket_id, token_hmac, token_ciphertext)
    values (
      v_ticket_id,
      extensions.hmac(convert_to(v_token, 'UTF8'), convert_to(v_hmac_key, 'UTF8'), 'sha256'),
      extensions.pgp_sym_encrypt(v_token, v_enc_key, 'cipher-algo=aes256')
    );

    ticket_id := v_ticket_id;
    public_reference := v_reference;
    qr_token := v_token;
    return next;
  end loop;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'tickets.issued', 'ticket_category', p_category_id,
          jsonb_build_object('event_id', p_event_id, 'quantity', p_quantity));
end;
$$;
revoke all on function public.issue_tickets(uuid, uuid, integer) from public, anon;
grant execute on function public.issue_tickets(uuid, uuid, integer) to authenticated;

-- -----------------------------------------------------------------------------
-- Révocation (TIC-04)
-- -----------------------------------------------------------------------------
create or replace function public.revoke_ticket(p_ticket_id uuid, p_reason text default null)
returns public.ticket_status
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_org uuid;
  v_status public.ticket_status;
begin
  select e.organization_id into v_org
  from public.tickets t join public.events e on e.id = t.event_id
  where t.id = p_ticket_id;
  if v_org is null
     or not private.has_org_role(v_org, array['owner','manager']::public.member_role[]) then
    raise exception 'Billet introuvable ou droits insuffisants' using errcode = '42501';
  end if;

  update public.tickets t
     set status = 'revoked', revoked_at = now(), revoked_by = v_actor
   where t.id = p_ticket_id and t.status = 'issued'
  returning t.status into v_status;

  if v_status is null then
    select t.status into v_status from public.tickets t where t.id = p_ticket_id;
    return v_status; -- déjà consommé ou révoqué : rien à faire
  end if;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org, v_actor, 'ticket.revoked', 'ticket', p_ticket_id,
          jsonb_build_object('reason', left(coalesce(p_reason, ''), 200)));
  return v_status;
end;
$$;
revoke all on function public.revoke_ticket(uuid, text) from public, anon;
grant execute on function public.revoke_ticket(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Validation d'un scan — seule autorité d'acceptation (SCN-01 à SCN-09)
-- -----------------------------------------------------------------------------
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
  -- 0. Session obligatoire. Sans acteur, rien n'est enregistré.
  if v_actor is null or p_request_id is null then
    return jsonb_build_object('request_id', p_request_id, 'result', 'unauthorized',
                              'server_time', v_now);
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
