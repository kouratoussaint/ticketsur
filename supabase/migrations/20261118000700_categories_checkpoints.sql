-- =============================================================================
-- TicketSûr — Migration 0700 : catégories de billets et portes (EVT-03, EVT-04)
-- =============================================================================
-- Écritures réservées aux propriétaires et gestionnaires, uniquement tant que
-- l'événement n'est ni clôturé, ni annulé, ni archivé.
--
-- EVT-03 « compteurs et limites transactionnels » : issue_tickets verrouille
-- désormais l'ÉVÉNEMENT puis la catégorie, et vérifie les deux limites (quota
-- de catégorie ET capacité de l'événement, toutes catégories confondues) sous
-- ces verrous. Ordre de verrouillage unique : événement → catégorie.
-- L'émission exige un événement publié ou en cours (jamais en brouillon).
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   42501 category_not_found | checkpoint_not_found | event_not_found
--   22023 category_name_invalid | category_capacity_invalid
--         | category_capacity_below_issued | checkpoint_name_invalid
--         | event_capacity_exceeded | category_capacity_exceeded
--   23505 category_name_taken | checkpoint_name_taken
--   55000 event_locked | category_has_tickets | event_not_published
-- =============================================================================

-- Événement modifiable (structure) : verrouillé, géré par l'appelant, actif.
create or replace function private.lock_configurable_event(p_event_id uuid)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;
  return v_event;
end;
$$;
revoke all on function private.lock_configurable_event(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Catégories
-- -----------------------------------------------------------------------------
create or replace function private.check_category_fields(p_name text, p_capacity integer)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_name is null or char_length(p_name) not between 1 and 60 then
    raise exception 'category_name_invalid'
      using errcode = '22023', detail = 'Nom de 1 à 60 caractères.';
  end if;
  if p_capacity is not null and (p_capacity < 1 or p_capacity > 1000000) then
    raise exception 'category_capacity_invalid'
      using errcode = '22023', detail = 'Quota de 1 à 1 000 000.';
  end if;
end;
$$;
revoke all on function private.check_category_fields(text, integer) from public, anon, authenticated;

create or replace function public.create_ticket_category(
  p_event_id uuid,
  p_name text,
  p_capacity integer default null
)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
begin
  v_event := private.lock_configurable_event(p_event_id);
  perform private.check_category_fields(v_name, p_capacity);
  if exists (select 1 from public.ticket_categories c
             where c.event_id = p_event_id and lower(c.name) = lower(v_name)) then
    raise exception 'category_name_taken'
      using errcode = '23505', detail = 'Une catégorie porte déjà ce nom.';
  end if;

  insert into public.ticket_categories (event_id, name, capacity)
  values (p_event_id, v_name, p_capacity)
  returning * into v_category;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.created', 'ticket_category', v_category.id,
          jsonb_build_object('event_id', p_event_id, 'name', v_name, 'capacity', p_capacity));
  return v_category;
end;
$$;
revoke all on function public.create_ticket_category(uuid, text, integer) from public, anon;
grant execute on function public.create_ticket_category(uuid, text, integer) to authenticated;

create or replace function public.update_ticket_category(
  p_category_id uuid,
  p_name text,
  p_capacity integer default null
)
returns public.ticket_categories
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event_id uuid;
  v_event public.events%rowtype;
  v_category public.ticket_categories%rowtype;
  v_issued integer;
begin
  select c.event_id into v_event_id from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  -- Ordre de verrouillage : événement, puis catégorie (comme issue_tickets).
  v_event := private.lock_configurable_event(v_event_id);
  select * into v_category from public.ticket_categories c where c.id = p_category_id for update;
  perform private.check_category_fields(v_name, p_capacity);
  if exists (select 1 from public.ticket_categories c
             where c.event_id = v_event_id and c.id <> p_category_id
               and lower(c.name) = lower(v_name)) then
    raise exception 'category_name_taken'
      using errcode = '23505', detail = 'Une catégorie porte déjà ce nom.';
  end if;
  if p_capacity is not null then
    select count(*) into v_issued from public.tickets t
    where t.category_id = p_category_id and t.status <> 'revoked';
    if v_issued > p_capacity then
      raise exception 'category_capacity_below_issued'
        using errcode = '22023', detail = format('%s billets déjà émis.', v_issued);
    end if;
  end if;

  update public.ticket_categories c
     set name = v_name, capacity = p_capacity
   where c.id = p_category_id
  returning * into v_category;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.updated', 'ticket_category', p_category_id,
          jsonb_build_object('name', v_name, 'capacity', p_capacity));
  return v_category;
end;
$$;
revoke all on function public.update_ticket_category(uuid, text, integer) from public, anon;
grant execute on function public.update_ticket_category(uuid, text, integer) to authenticated;

create or replace function public.delete_ticket_category(p_category_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
  v_event public.events%rowtype;
  v_name text;
begin
  select c.event_id, c.name into v_event_id, v_name
  from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_configurable_event(v_event_id);
  perform 1 from public.ticket_categories c where c.id = p_category_id for update;
  -- Même révoqués, les billets restent rattachés à leur catégorie (historique).
  if exists (select 1 from public.tickets t where t.category_id = p_category_id) then
    raise exception 'category_has_tickets'
      using errcode = '55000', detail = 'Des billets existent dans cette catégorie.';
  end if;
  delete from public.ticket_categories c where c.id = p_category_id;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'category.deleted', 'ticket_category', p_category_id,
          jsonb_build_object('event_id', v_event_id, 'name', v_name));
end;
$$;
revoke all on function public.delete_ticket_category(uuid) from public, anon;
grant execute on function public.delete_ticket_category(uuid) to authenticated;

-- Catégories d'un événement avec leurs compteurs. Réservé aux gestionnaires
-- (les contrôleurs ne voient pas les volumes de billets).
create or replace function public.event_categories(p_event_id uuid)
returns table (
  id uuid,
  event_id uuid,
  name text,
  capacity integer,
  issued integer,
  redeemed integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.events e
    where e.id = p_event_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  ) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  return query
    select c.id, c.event_id, c.name, c.capacity,
           count(t.id) filter (where t.status <> 'revoked')::integer,
           count(t.id) filter (where t.status = 'redeemed')::integer
    from public.ticket_categories c
    left join public.tickets t on t.category_id = c.id
    where c.event_id = p_event_id
    group by c.id
    order by c.created_at, c.name;
end;
$$;
revoke all on function public.event_categories(uuid) from public, anon;
grant execute on function public.event_categories(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Portes (points de contrôle)
-- -----------------------------------------------------------------------------
create or replace function private.check_checkpoint_name(p_event_id uuid, p_id uuid, p_name text)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_name is null or char_length(p_name) not between 1 and 60 then
    raise exception 'checkpoint_name_invalid'
      using errcode = '22023', detail = 'Nom de 1 à 60 caractères.';
  end if;
  if exists (select 1 from public.checkpoints cp
             where cp.event_id = p_event_id and cp.id is distinct from p_id
               and lower(cp.name) = lower(p_name)) then
    raise exception 'checkpoint_name_taken'
      using errcode = '23505', detail = 'Une porte porte déjà ce nom.';
  end if;
end;
$$;
revoke all on function private.check_checkpoint_name(uuid, uuid, text) from public, anon, authenticated;

create or replace function public.create_checkpoint(p_event_id uuid, p_name text)
returns public.checkpoints
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event public.events%rowtype;
  v_checkpoint public.checkpoints%rowtype;
begin
  v_event := private.lock_configurable_event(p_event_id);
  perform private.check_checkpoint_name(p_event_id, null, v_name);
  insert into public.checkpoints (event_id, name) values (p_event_id, v_name)
  returning * into v_checkpoint;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'checkpoint.created', 'checkpoint', v_checkpoint.id,
          jsonb_build_object('event_id', p_event_id, 'name', v_name));
  return v_checkpoint;
end;
$$;
revoke all on function public.create_checkpoint(uuid, text) from public, anon;
grant execute on function public.create_checkpoint(uuid, text) to authenticated;

-- Renommer et/ou activer/désactiver. Désactiver une porte refuse
-- immédiatement les scans qui s'y présentent (validate_scan exige cp.active).
create or replace function public.update_checkpoint(
  p_checkpoint_id uuid,
  p_name text,
  p_active boolean
)
returns public.checkpoints
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_name text := private.normalize_text(p_name);
  v_event_id uuid;
  v_event public.events%rowtype;
  v_checkpoint public.checkpoints%rowtype;
begin
  select cp.event_id into v_event_id from public.checkpoints cp where cp.id = p_checkpoint_id;
  if v_event_id is null then
    raise exception 'checkpoint_not_found'
      using errcode = '42501', detail = 'Porte introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_configurable_event(v_event_id);
  perform private.check_checkpoint_name(v_event_id, p_checkpoint_id, v_name);
  if p_active is null then
    raise exception 'checkpoint_name_invalid' using errcode = '22023', detail = 'État requis.';
  end if;

  update public.checkpoints cp
     set name = v_name, active = p_active
   where cp.id = p_checkpoint_id
  returning * into v_checkpoint;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'checkpoint.updated', 'checkpoint', p_checkpoint_id,
          jsonb_build_object('name', v_name, 'active', p_active));
  return v_checkpoint;
end;
$$;
revoke all on function public.update_checkpoint(uuid, text, boolean) from public, anon;
grant execute on function public.update_checkpoint(uuid, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Émission : capacité de l'événement + statut publié (remplace la version 0200)
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
  v_event_existing integer;
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

  -- Verrou de l'événement : sérialise les émissions de TOUTES ses catégories
  -- (capacité globale exacte) et les changements de capacité.
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found
     or not private.has_org_role(v_event.organization_id, array['owner','manager']::public.member_role[]) then
    raise exception 'Événement introuvable ou droits insuffisants' using errcode = '42501';
  end if;
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'Événement fermé : émission impossible' using errcode = '22023';
  end if;
  if v_event.status = 'draft' then
    raise exception 'event_not_published'
      using errcode = '55000', detail = 'Publiez l''événement avant d''émettre des billets.';
  end if;

  select * into v_category from public.ticket_categories c
  where c.id = p_category_id and c.event_id = p_event_id
  for update;
  if not found then
    raise exception 'Catégorie inconnue pour cet événement' using errcode = '22023';
  end if;

  select count(*) into v_existing from public.tickets t
  where t.category_id = p_category_id and t.status <> 'revoked';
  if v_category.capacity is not null and v_existing + p_quantity > v_category.capacity then
    raise exception 'category_capacity_exceeded'
      using errcode = '22023',
            detail = format('Quota de la catégorie dépassé (%s restants).', v_category.capacity - v_existing);
  end if;

  if v_event.capacity is not null then
    select count(*) into v_event_existing from public.tickets t
    where t.event_id = p_event_id and t.status <> 'revoked';
    if v_event_existing + p_quantity > v_event.capacity then
      raise exception 'event_capacity_exceeded'
        using errcode = '22023',
              detail = format('Capacité de l''événement dépassée (%s restants).', v_event.capacity - v_event_existing);
    end if;
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
