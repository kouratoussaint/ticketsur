-- =============================================================================
-- Tikéo — Lot 4-11c : événements et tickets depuis la console (ADR 0040)
-- =============================================================================
-- Décisions de Toussaint (21/11) : la console voit tous les événements, les
-- modifie, change leur état (annuler un événement annule ses tickets non
-- entrés et prévient leurs détenteurs), les déplace vers une autre structure,
-- met à la corbeille un brouillon sans ticket ; elle retrouve un ticket sur
-- toute la plateforme, l'annule, change son titulaire ; elle émet des tickets
-- à la place d'un promoteur seulement si le réglage de la console le permet
-- (désactivé par défaut). Jamais de QR affiché ni régénéré.
--
-- Permissions (migration 4900) : `events` (modération, super) pour les
-- événements ; `tickets` (support, super) pour les tickets. Lecture des
-- listes et fiches : tout administrateur.
--
-- Motifs dans `private.admin_action_log` (jamais dans audit_logs).
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   P0002 event_not_found | ticket_not_found | category_not_found
--   55000 event_trashed | event_not_trashed | event_locked | event_invalid_transition
--         | event_already_ended | event_incomplete | event_has_tickets
--         | event_not_trashable | event_same_organization | event_has_invoice
--         | organization_inactive | ticket_not_revocable | ticket_not_editable
--         | admin_issue_disabled
--   22023 event_* (champs, comme pour le promoteur) | search_query_invalid
--         | issue_quantity_invalid

alter table public.events
  add column trashed_at timestamptz;

-- Un brouillon à la corbeille disparaît pour les membres de la structure.
drop policy events_visible on public.events;
create policy events_visible on public.events for select to authenticated
using (private.can_see_event(id) and trashed_at is null);

-- Événement visé par une action de la console : verrouillé, hors corbeille.
create function private.lock_console_event(p_event_id uuid)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    raise exception 'event_not_found' using errcode = 'P0002', detail = 'Événement introuvable.';
  end if;
  if v_event.trashed_at is not null then
    raise exception 'event_trashed'
      using errcode = '55000', detail = 'Cet événement est à la corbeille : restaurez-le d''abord.';
  end if;
  return v_event;
end;
$$;
revoke all on function private.lock_console_event(uuid) from public, anon, authenticated;

-- Annule les tickets non entrés d'un événement et prévient leurs détenteurs
-- (un message par détenteur). Une seule requête.
create function private.cancel_event_tickets(p_event_id uuid, out tickets integer, out holders integer)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_title text;
  v_org text;
begin
  select e.title, o.name into v_title, v_org
    from public.events e join public.organizations o on o.id = e.organization_id
   where e.id = p_event_id;
  with revoked as (
    update public.tickets t
       set status = 'revoked', revoked_at = now(), revoked_by = v_actor
     where t.event_id = p_event_id and t.status = 'issued' and t.entries_used = 0
    returning t.id, t.holder_user_id
  ), pushed as (
    insert into public.push_outbox (user_id, title, body, route)
    select p.id,
           case when p.locale = 'en' then 'Event cancelled' else 'Événement annulé' end,
           left(case when p.locale = 'en'
                     then '“' || v_title || '” is cancelled: your ticket is no longer valid. Organizer: '
                          || v_org || '.'
                     else '« ' || v_title || ' » est annulé : votre ticket n''est plus valable. Organisateur : '
                          || v_org || '.' end, 240),
           '/portefeuille'
      from (select distinct r.holder_user_id from revoked r where r.holder_user_id is not null) h
      join public.profiles p on p.id = h.holder_user_id and p.deleted_at is null
    returning 1
  )
  select count(*), count(distinct r.holder_user_id) into tickets, holders from revoked r;
end;
$$;
revoke all on function private.cancel_event_tickets(uuid) from public, anon, authenticated;

-- Émission par l'administrateur : réglage de la console activé et
-- permission `tickets` (décision 8).
create function private.admin_may_issue_tickets()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.is_admin_account()
     and (not private.has_verified_factor(auth.uid()) or private.session_aal() = 'aal2')
     and private.admin_can('tickets')
     and private.console_setting_bool('admin_issue_tickets')
$$;
revoke all on function private.admin_may_issue_tickets() from public, anon, authenticated;

-- Émission (corps de 4500) : l'administrateur autorisé ci-dessus passe le
-- contrôle des rôles de la structure.
create or replace function private.issue_ticket_rows(p_event_id uuid, p_rows jsonb)
returns table (
  line integer,
  ticket_id uuid,
  public_reference text,
  qr_token text,
  category_id uuid,
  holder_name text
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_row record;
  v_holder record;
  v_quota record;
  v_event_existing integer;
  v_total integer;
  v_token text;
  v_ticket_id uuid;
  v_reference text;
  v_hmac_key text;
  v_enc_key text;
  v_batch_id uuid;
  v_batch_number integer;
begin
  if v_actor is null then
    raise exception 'Authentification requise' using errcode = '42501';
  end if;
  if p_rows is null or jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) < 1 then
    raise exception 'issue_rows_invalid'
      using errcode = '22023', detail = 'Aucun ticket à émettre.';
  end if;
  v_total := jsonb_array_length(p_rows);

  -- Verrou de l'événement : sérialise les émissions de TOUTES ses catégories
  -- (capacité globale exacte) et les changements de capacité.
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found
     or not (private.has_org_role(v_event.organization_id, array['owner','manager']::public.member_role[])
             or private.admin_may_issue_tickets()) then
    raise exception 'Événement introuvable ou droits insuffisants' using errcode = '42501';
  end if;
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'Événement fermé : émission impossible' using errcode = '22023';
  end if;
  if v_event.status = 'draft' then
    raise exception 'event_not_published'
      using errcode = '55000', detail = 'Publiez l''événement avant d''émettre des tickets.';
  end if;

  -- Lignes normalisées (le titulaire est contrôlé avant toute écriture).
  create temp table if not exists pg_temp.issue_rows (
    line integer primary key,
    category_id uuid,
    holder_name text,
    holder_phone text,
    holder_email text
  ) on commit drop;
  truncate pg_temp.issue_rows;

  for v_row in
    select r.ordinality::integer as line, r.value as item
    from jsonb_array_elements(p_rows) with ordinality r
  loop
    if jsonb_typeof(v_row.item) <> 'object' then
      raise exception 'issue_rows_invalid'
        using errcode = '22023', detail = format('Ligne %s : format invalide.', v_row.line);
    end if;
    select * into v_holder
    from private.check_holder(v_row.item->>'name', v_row.item->>'phone',
                              v_row.item->>'email', case when v_total > 1 then v_row.line end);
    insert into pg_temp.issue_rows
    values (v_row.line,
            nullif(v_row.item->>'category_id', '')::uuid,
            v_holder.name, v_holder.phone, v_holder.email);
  end loop;

  if exists (
    select 1 from pg_temp.issue_rows r
    where r.category_id is null
       or not exists (select 1 from public.ticket_categories c
                      where c.id = r.category_id and c.event_id = p_event_id)
  ) then
    raise exception 'category_not_found'
      using errcode = '22023', detail = 'Catégorie inconnue pour cet événement.';
  end if;

  -- Quotas des catégories concernées (verrouillées dans un ordre stable).
  perform 1 from public.ticket_categories c
  where c.id in (select r.category_id from pg_temp.issue_rows r)
  order by c.id
  for update;

  for v_quota in
    select c.name, c.capacity, count(r.line)::integer as wanted,
           (select count(*) from public.tickets t
            where t.category_id = c.id and t.status <> 'revoked')::integer as existing
    from pg_temp.issue_rows r
    join public.ticket_categories c on c.id = r.category_id
    group by c.id, c.name, c.capacity
  loop
    if v_quota.capacity is not null and v_quota.existing + v_quota.wanted > v_quota.capacity then
      raise exception 'category_capacity_exceeded'
        using errcode = '22023',
              detail = format('Quota de la catégorie « %s » dépassé (%s restants).',
                              v_quota.name, greatest(v_quota.capacity - v_quota.existing, 0));
    end if;
  end loop;

  if v_event.capacity is not null then
    select count(*) into v_event_existing from public.tickets t
    where t.event_id = p_event_id and t.status <> 'revoked';
    if v_event_existing + v_total > v_event.capacity then
      raise exception 'event_capacity_exceeded'
        using errcode = '22023',
              detail = format('Capacité de l''événement dépassée (%s restants).',
                              greatest(v_event.capacity - v_event_existing, 0));
    end if;
  end if;

  -- Lot de génération : un par appel, numéroté dans l'événement (l'événement
  -- est verrouillé plus haut : numérotation sans trou ni doublon).
  select coalesce(max(b.number), 0) + 1 into v_batch_number
    from public.ticket_batches b where b.event_id = p_event_id;
  insert into public.ticket_batches (event_id, number, created_by)
  values (p_event_id, v_batch_number, v_actor)
  returning id into v_batch_id;

  v_hmac_key := private.vault_secret('ticketsur_qr_hmac_key');
  v_enc_key := private.vault_secret('ticketsur_qr_encryption_key');

  for v_row in select r.* from pg_temp.issue_rows r order by r.line loop
    v_token := private.new_qr_token();
    loop
      v_reference := private.new_public_reference();
      begin
        insert into public.tickets (event_id, category_id, public_reference, issued_by,
                                    holder_name, holder_phone, holder_email, batch_id)
        values (p_event_id, v_row.category_id, v_reference, v_actor,
                v_row.holder_name, v_row.holder_phone, v_row.holder_email, v_batch_id)
        returning id into v_ticket_id;
        exit;
      exception when unique_violation then
        -- Collision de référence publique (~1e-5 pour 10 000 tickets) : on retire.
        null;
      end;
    end loop;

    insert into private.ticket_secrets (ticket_id, token_hmac, token_ciphertext)
    values (
      v_ticket_id,
      extensions.hmac(convert_to(v_token, 'UTF8'), convert_to(v_hmac_key, 'UTF8'), 'sha256'),
      extensions.pgp_sym_encrypt(v_token, v_enc_key, 'cipher-algo=aes256')
    );

    line := v_row.line;
    ticket_id := v_ticket_id;
    public_reference := v_reference;
    qr_token := v_token;
    category_id := v_row.category_id;
    holder_name := v_row.holder_name;
    return next;
  end loop;

  -- Journal : une entrée par catégorie, sans aucune donnée personnelle.
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  select v_event.organization_id, v_actor, 'tickets.issued', 'ticket_category', r.category_id,
         jsonb_build_object('event_id', p_event_id, 'quantity', count(*), 'batch', v_batch_number,
                            'named', count(*) filter (where r.holder_name is not null
                                                         or r.holder_phone is not null
                                                         or r.holder_email is not null))
  from pg_temp.issue_rows r
  group by r.category_id;
end;
$$;
revoke all on function private.issue_ticket_rows(uuid, jsonb) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Événements : liste et fiche
-- -----------------------------------------------------------------------------
create function public.admin_events(
  p_search text default null,
  p_status public.event_status default null,
  p_organization_id uuid default null,
  p_limit integer default 30,
  p_offset integer default 0
)
returns table (
  id uuid,
  title text,
  status public.event_status,
  starts_at timestamptz,
  ends_at timestamptz,
  city text,
  is_public boolean,
  blocked boolean,
  organization_id uuid,
  organization_name text,
  tickets integer,
  admitted integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(private.fold(trim(coalesce(p_search, ''))), '');
begin
  perform private.require_platform_admin();
  if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset < 0 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  return query
  select e.id, e.title, e.status, e.starts_at, e.ends_at, e.city, e.is_public,
         e.public_blocked_at is not null, o.id, o.name,
         (select count(*)::integer from public.tickets t where t.event_id = e.id),
         (select count(*)::integer from public.tickets t
           where t.event_id = e.id and t.status <> 'revoked' and t.entries_used > 0)
    from public.events e
    join public.organizations o on o.id = e.organization_id
   where e.trashed_at is null
     and (p_status is null or e.status = p_status)
     and (p_organization_id is null or e.organization_id = p_organization_id)
     and (v_search is null
          or private.fold(e.title) like '%' || v_search || '%'
          or private.fold(coalesce(e.city, '')) like '%' || v_search || '%'
          or private.fold(o.name) like '%' || v_search || '%')
   order by e.starts_at desc, e.id
   limit p_limit offset p_offset;
end;
$$;
revoke all on function public.admin_events(text, public.event_status, uuid, integer, integer) from public, anon;
grant execute on function public.admin_events(text, public.event_status, uuid, integer, integer) to authenticated;

create function public.admin_event_detail(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
begin
  perform private.require_platform_admin();
  select * into v_event from public.events e where e.id = p_event_id;
  if not found then
    raise exception 'event_not_found' using errcode = 'P0002', detail = 'Événement introuvable.';
  end if;
  return jsonb_build_object(
    'id', v_event.id,
    'title', v_event.title,
    'status', v_event.status,
    'kind', v_event.kind,
    'starts_at', v_event.starts_at,
    'ends_at', v_event.ends_at,
    'timezone', v_event.timezone,
    'venue', v_event.venue,
    'city', v_event.city,
    'venue_address', v_event.venue_address,
    'description', v_event.description,
    'tagline', v_event.tagline,
    'capacity', v_event.capacity,
    'is_public', v_event.is_public,
    'cover_path', v_event.cover_path,
    'blocked_reason', v_event.public_blocked_reason,
    'blocked', v_event.public_blocked_at is not null,
    'trashed_at', v_event.trashed_at,
    'purge_due_at', v_event.trashed_at + interval '30 days',
    'organization', (select jsonb_build_object('id', o.id, 'name', o.name, 'status', o.status,
                                               'closed', o.closed_at is not null)
                       from public.organizations o where o.id = v_event.organization_id),
    'categories', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', c.id, 'name', c.name, 'capacity', c.capacity,
               'is_invitation', c.is_invitation, 'price', c.indicative_price,
               'issued', (select count(*) from public.tickets t
                           where t.category_id = c.id and t.status <> 'revoked'),
               'admitted', (select count(*) from public.tickets t
                             where t.category_id = c.id and t.status <> 'revoked'
                               and t.entries_used > 0)) order by c.created_at, c.name)
        from public.ticket_categories c where c.event_id = v_event.id), '[]'::jsonb),
    'checkpoints', coalesce((
      select jsonb_agg(cp.name order by cp.name)
        from public.checkpoints cp where cp.event_id = v_event.id and cp.active), '[]'::jsonb),
    'tickets_total', (select count(*) from public.tickets t where t.event_id = v_event.id),
    'tickets_valid', (select count(*) from public.tickets t
                       where t.event_id = v_event.id and t.status = 'issued'),
    'tickets_admitted', (select count(*) from public.tickets t
                          where t.event_id = v_event.id and t.status <> 'revoked'
                            and t.entries_used > 0),
    'tickets_revoked', (select count(*) from public.tickets t
                         where t.event_id = v_event.id and t.status = 'revoked'),
    'tickets_to_cancel', (select count(*) from public.tickets t
                           where t.event_id = v_event.id and t.status = 'issued'
                             and t.entries_used = 0),
    'holders_to_notify', (select count(distinct t.holder_user_id) from public.tickets t
                           where t.event_id = v_event.id and t.status = 'issued'
                             and t.entries_used = 0 and t.holder_user_id is not null),
    'has_invoice', exists (select 1 from public.billing_invoices b where b.event_id = v_event.id),
    'actions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'action', a.action, 'at', a.created_at, 'reason', a.reason,
               'by', coalesce(p.display_name, '—')) order by a.created_at desc, a.id desc)
        from (select * from private.admin_action_log l
               where l.target_id = v_event.id
               order by l.created_at desc, l.id desc limit 20) a
        left join public.profiles p on p.id = a.actor_id), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_event_detail(uuid) from public, anon;
grant execute on function public.admin_event_detail(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Événements : modifier, changer l'état, déplacer
-- -----------------------------------------------------------------------------
create function private.notify_event_owner(
  p_event public.events, p_title_fr text, p_title_en text, p_reason text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_owner uuid := (select o.owner_id from public.organizations o where o.id = p_event.organization_id);
begin
  perform private.notify_user(v_owner, p_title_fr, p_title_en,
    '« ' || p_event.title || ' » — par l''équipe Tikéo. Motif : ' || p_reason,
    '“' || p_event.title || '” — by the Tikéo team. Reason: ' || p_reason);
end;
$$;
revoke all on function private.notify_event_owner(public.events, text, text, text)
  from public, anon, authenticated;

create function public.admin_update_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_timezone text,
  p_venue text,
  p_city text,
  p_venue_address text,
  p_description text,
  p_tagline text,
  p_capacity integer,
  p_is_public boolean,
  p_reason text,
  p_notify boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_title text := private.normalize_text(p_title);
  v_venue text := private.normalize_text(p_venue);
  v_city text := private.normalize_text(p_city);
  v_address text := private.normalize_text(p_venue_address);
  v_description text := private.normalize_long_text(p_description);
  v_tagline text := private.normalize_text(p_tagline);
  v_event public.events%rowtype;
  v_fields text[] := '{}';
  v_issued integer;
begin
  perform private.require_admin('events');
  v_event := private.lock_console_event(p_event_id);
  if v_event.status not in ('draft', 'published', 'in_progress') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;
  perform private.check_event_fields(v_title, v_venue, p_timezone, p_starts_at, p_ends_at, p_capacity);
  perform private.check_event_content(v_city, v_event.country_code, v_address,
                                      v_event.latitude, v_event.longitude, v_description);
  if v_tagline is not null and char_length(v_tagline) > 60 then
    raise exception 'event_tagline_invalid'
      using errcode = '22023', detail = 'Accroche de 60 caractères au plus.';
  end if;
  if p_capacity is not null then
    select count(*) into v_issued from public.tickets t
     where t.event_id = p_event_id and t.status <> 'revoked';
    if v_issued > p_capacity then
      raise exception 'event_capacity_below_issued'
        using errcode = '22023', detail = format('%s tickets déjà émis.', v_issued);
    end if;
  end if;

  if v_title is distinct from v_event.title then v_fields := v_fields || 'title'::text; end if;
  if p_starts_at is distinct from v_event.starts_at or p_ends_at is distinct from v_event.ends_at
     or p_timezone is distinct from v_event.timezone then
    v_fields := v_fields || 'dates'::text;
  end if;
  if v_venue is distinct from v_event.venue or v_city is distinct from v_event.city
     or v_address is distinct from v_event.venue_address then
    v_fields := v_fields || 'place'::text;
  end if;
  if v_description is distinct from v_event.description then
    v_fields := v_fields || 'description'::text;
  end if;
  if v_tagline is distinct from v_event.tagline then v_fields := v_fields || 'tagline'::text; end if;
  if p_capacity is distinct from v_event.capacity then v_fields := v_fields || 'capacity'::text; end if;
  if coalesce(p_is_public, v_event.is_public) is distinct from v_event.is_public then
    v_fields := v_fields || 'public'::text;
  end if;

  update public.events e
     set title = v_title, starts_at = p_starts_at, ends_at = p_ends_at, timezone = p_timezone,
         venue = v_venue, city = v_city, venue_address = v_address,
         description = v_description, tagline = v_tagline, capacity = p_capacity,
         is_public = coalesce(p_is_public, e.is_public), updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  perform private.log_admin_action('admin.event_updated', 'event', p_event_id, v_reason,
    jsonb_build_object('fields', to_jsonb(v_fields)), v_event.organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_event_owner(v_event, 'Événement modifié', 'Event updated', v_reason);
  end if;
  return jsonb_build_object('fields', to_jsonb(v_fields));
end;
$$;
revoke all on function public.admin_update_event(uuid, text, timestamptz, timestamptz, text, text, text, text, text, text, integer, boolean, text, boolean) from public, anon;
grant execute on function public.admin_update_event(uuid, text, timestamptz, timestamptz, text, text, text, text, text, text, integer, boolean, text, boolean) to authenticated;

create function public.admin_set_event_status(
  p_event_id uuid,
  p_status public.event_status,
  p_reason text,
  p_notify boolean default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_event public.events%rowtype;
  v_from public.event_status;
  v_tickets integer := 0;
  v_holders integer := 0;
begin
  perform private.require_admin('events');
  v_event := private.lock_console_event(p_event_id);
  v_from := v_event.status;
  -- Transitions du promoteur, et l'annulation d'un événement en cours.
  if p_status is null
     or not (private.event_transition_allowed(v_from, p_status)
             or (v_from = 'in_progress' and p_status = 'cancelled')) then
    raise exception 'event_invalid_transition'
      using errcode = '55000', detail = format('%s → %s interdit.', v_from, p_status);
  end if;
  if p_status = 'published' and v_event.ends_at <= now() then
    raise exception 'event_already_ended'
      using errcode = '55000', detail = 'Impossible de publier un événement terminé.';
  end if;
  if p_status = 'published' and (v_event.cover_path is null or v_event.city is null) then
    raise exception 'event_incomplete'
      using errcode = '55000',
            detail = 'Ajoutez une photo de couverture et une ville avant de publier.';
  end if;
  if v_from = 'published' and p_status = 'draft'
     and exists (select 1 from public.tickets t where t.event_id = p_event_id) then
    raise exception 'event_has_tickets'
      using errcode = '55000', detail = 'Des tickets existent : retour en brouillon impossible.';
  end if;

  update public.events e
     set status = p_status,
         control_started_at = case when p_status = 'in_progress' then now()
                                   else e.control_started_at end,
         control_stopped_at = case when v_from = 'in_progress' and p_status in ('closed', 'cancelled')
                                   then now() else e.control_stopped_at end,
         updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  if p_status = 'cancelled' then
    select c.tickets, c.holders into v_tickets, v_holders
      from private.cancel_event_tickets(p_event_id) c;
  end if;

  perform private.log_admin_action('admin.event_status_changed', 'event', p_event_id, v_reason,
    jsonb_build_object('from', v_from, 'to', p_status, 'tickets_cancelled', v_tickets),
    v_event.organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_event_owner(v_event, 'État de l''événement changé',
                                       'Event status changed', v_reason);
  end if;
  return jsonb_build_object('from', v_from, 'to', p_status,
                            'tickets_cancelled', v_tickets, 'holders_notified', v_holders);
end;
$$;
revoke all on function public.admin_set_event_status(uuid, public.event_status, text, boolean) from public, anon;
grant execute on function public.admin_set_event_status(uuid, public.event_status, text, boolean) to authenticated;

-- Erreur de structure à la création : l'événement change de structure avec
-- ses catégories, portes et tickets ; les affectations de l'ancienne équipe
-- sont retirées. Jamais un événement déjà facturé.
create function public.admin_move_event(
  p_event_id uuid,
  p_organization_id uuid,
  p_reason text,
  p_notify boolean default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_event public.events%rowtype;
  v_target public.organizations%rowtype;
  v_from uuid;
begin
  perform private.require_admin('events');
  v_event := private.lock_console_event(p_event_id);
  v_target := private.lock_console_organization(p_organization_id);
  if v_target.status <> 'active' then
    raise exception 'organization_inactive'
      using errcode = '55000', detail = 'La structure de destination est suspendue.';
  end if;
  if v_target.id = v_event.organization_id then
    raise exception 'event_same_organization'
      using errcode = '55000', detail = 'L''événement est déjà dans cette structure.';
  end if;
  if exists (select 1 from public.billing_invoices b where b.event_id = p_event_id) then
    raise exception 'event_has_invoice'
      using errcode = '55000', detail = 'Événement déjà facturé : déplacement impossible.';
  end if;
  v_from := v_event.organization_id;
  update public.event_assignments a set active = false
   where a.event_id = p_event_id and a.active;
  update public.events e set organization_id = v_target.id, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;

  perform private.log_admin_action('admin.event_moved', 'event', p_event_id, v_reason,
    jsonb_build_object('from_organization', v_from, 'to_organization', v_target.id), v_target.id);
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_from, auth.uid(), 'admin.event_moved', 'event', p_event_id,
          jsonb_build_object('from_organization', v_from, 'to_organization', v_target.id));
  if private.should_notify(p_notify) then
    perform private.notify_event_owner(v_event, 'Événement déplacé', 'Event moved', v_reason);
    perform private.notify_user((select o.owner_id from public.organizations o where o.id = v_from),
      'Événement déplacé', 'Event moved',
      '« ' || v_event.title || ' » a été déplacé vers « ' || v_target.name || ' ». Motif : ' || v_reason,
      '“' || v_event.title || '” was moved to “' || v_target.name || '”. Reason: ' || v_reason);
  end if;
end;
$$;
revoke all on function public.admin_move_event(uuid, uuid, text, boolean) from public, anon;
grant execute on function public.admin_move_event(uuid, uuid, text, boolean) to authenticated;

-- -----------------------------------------------------------------------------
-- Événements : corbeille (brouillon sans ticket)
-- -----------------------------------------------------------------------------
create function public.admin_trash_event(p_event_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_event public.events%rowtype;
begin
  perform private.require_admin('events');
  v_event := private.lock_console_event(p_event_id);
  if v_event.status <> 'draft'
     or exists (select 1 from public.tickets t where t.event_id = p_event_id) then
    raise exception 'event_not_trashable'
      using errcode = '55000',
            detail = 'Seul un brouillon sans ticket va à la corbeille : annulez plutôt l''événement.';
  end if;
  update public.events e set trashed_at = now(), updated_at = now() where e.id = p_event_id;
  perform private.log_admin_action('admin.event_trashed', 'event', p_event_id, v_reason,
    '{}'::jsonb, v_event.organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_event_owner(v_event, 'Brouillon supprimé', 'Draft deleted', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_trash_event(uuid, text, boolean) from public, anon;
grant execute on function public.admin_trash_event(uuid, text, boolean) to authenticated;

create function public.admin_restore_event(p_event_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_event public.events%rowtype;
begin
  perform private.require_admin('events');
  select * into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    raise exception 'event_not_found' using errcode = 'P0002', detail = 'Événement introuvable.';
  end if;
  if v_event.trashed_at is null then
    raise exception 'event_not_trashed'
      using errcode = '55000', detail = 'Cet événement n''est pas à la corbeille.';
  end if;
  update public.events e set trashed_at = null, updated_at = now() where e.id = p_event_id;
  perform private.log_admin_action('admin.event_restored', 'event', p_event_id, v_reason,
    '{}'::jsonb, v_event.organization_id);
  if private.should_notify(p_notify) then
    perform private.notify_event_owner(v_event, 'Brouillon restauré', 'Draft restored', v_reason);
  end if;
end;
$$;
revoke all on function public.admin_restore_event(uuid, text, boolean) from public, anon;
grant execute on function public.admin_restore_event(uuid, text, boolean) to authenticated;

-- Effacement réel après 30 jours (brouillon sans ticket : rien à garder).
-- Un lien inattendu (abonnement lié…) le laisse à la corbeille.
create function private.purge_due_events()
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  r record;
  v_count integer := 0;
begin
  for r in
    select e.id, e.organization_id from public.events e
     where e.trashed_at is not null and e.trashed_at <= now() - interval '30 days'
       and e.status = 'draft'
       and not exists (select 1 from public.tickets t where t.event_id = e.id)
     for update skip locked
  loop
    begin
      delete from public.events e where e.id = r.id;
      insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
      values (r.organization_id, auth.uid(), 'admin.event_purged', 'event', r.id, '{}'::jsonb);
      v_count := v_count + 1;
    exception when foreign_key_violation then
      null;
    end;
  end loop;
  return v_count;
end;
$$;
revoke all on function private.purge_due_events() from public, anon, authenticated;

create function private.purge_trash()
returns integer
language sql
volatile
security definer
set search_path = ''
as $$
  select private.purge_due_organizations() + private.purge_due_events()
$$;
revoke all on function private.purge_trash() from public, anon, authenticated;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule('tikeo-trash-purge', '23 3 * * *', 'select private.purge_trash()');
  end if;
end;
$$;

-- Corbeille : structures et événements.
create or replace function public.admin_trash()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return coalesce((
    select jsonb_agg(x.item order by x.trashed_at desc)
      from (
        select o.trashed_at,
               jsonb_build_object('kind', 'organization', 'id', o.id, 'name', o.name,
                                  'owner_name', p.display_name, 'trashed_at', o.trashed_at,
                                  'purge_due_at', o.trashed_at + interval '30 days') as item
          from public.organizations o
          join public.profiles p on p.id = o.owner_id
         where o.trashed_at is not null and o.purged_at is null
        union all
        select e.trashed_at,
               jsonb_build_object('kind', 'event', 'id', e.id, 'name', e.title,
                                  'owner_name', o.name, 'trashed_at', e.trashed_at,
                                  'purge_due_at', e.trashed_at + interval '30 days')
          from public.events e
          join public.organizations o on o.id = e.organization_id
         where e.trashed_at is not null
      ) x), '[]'::jsonb);
end;
$$;

-- -----------------------------------------------------------------------------
-- Tickets : recherche, fiche, annulation, titulaire, émission
-- -----------------------------------------------------------------------------
create function public.admin_find_tickets(p_query text, p_limit integer default 30)
returns table (
  id uuid,
  public_reference text,
  status public.ticket_status,
  holder_name text,
  event_id uuid,
  event_title text,
  starts_at timestamptz,
  organization_name text,
  category_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := btrim(coalesce(p_query, ''));
  v_folded text;
  v_digits text;
  v_reference text;
begin
  perform private.require_platform_admin();
  if char_length(v_query) not between 3 and 60 then
    raise exception 'search_query_invalid'
      using errcode = '22023', detail = 'De 3 à 60 caractères.';
  end if;
  if p_limit is null or p_limit not between 1 and 50 then
    raise exception 'page_invalid' using errcode = '22023', detail = 'Page invalide.';
  end if;
  v_folded := private.fold(v_query);
  v_digits := regexp_replace(v_query, '\D', '', 'g');
  v_reference := upper(v_query);
  return query
  select t.id, t.public_reference, t.status, t.holder_name, e.id, e.title, e.starts_at,
         o.name, c.name
    from public.tickets t
    join public.events e on e.id = t.event_id
    join public.organizations o on o.id = e.organization_id
    join public.ticket_categories c on c.id = t.category_id
   where t.public_reference like v_reference || '%'
      or (char_length(v_digits) >= 4 and t.holder_phone like '%' || v_digits || '%')
      or (t.holder_name is not null and private.fold(t.holder_name) like '%' || v_folded || '%')
   order by (t.public_reference = v_reference) desc, e.starts_at desc, t.id
   limit p_limit;
end;
$$;
revoke all on function public.admin_find_tickets(text, integer) from public, anon;
grant execute on function public.admin_find_tickets(text, integer) to authenticated;

create function public.admin_ticket_detail(p_ticket_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
begin
  perform private.require_platform_admin();
  select * into v_ticket from public.tickets t where t.id = p_ticket_id;
  if not found then
    raise exception 'ticket_not_found' using errcode = 'P0002', detail = 'Ticket introuvable.';
  end if;
  -- Jamais le QR ni son jeton.
  return jsonb_build_object(
    'id', v_ticket.id,
    'public_reference', v_ticket.public_reference,
    'event_number', v_ticket.event_number,
    'status', v_ticket.status,
    'issued_at', v_ticket.issued_at,
    'revoked_at', v_ticket.revoked_at,
    'holder_name', v_ticket.holder_name,
    'holder_phone', v_ticket.holder_phone,
    'holder_email', v_ticket.holder_email,
    'wallet_owner', (select p.display_name from public.profiles p where p.id = v_ticket.holder_user_id),
    'entries_used', v_ticket.entries_used,
    'first_entry_at', v_ticket.first_entry_at,
    'first_entry_door', (select cp.name from public.checkpoints cp
                          where cp.id = coalesce(v_ticket.first_entry_checkpoint_id,
                                                 v_ticket.redeemed_checkpoint_id)),
    'last_entry_at', v_ticket.last_entry_at,
    'category', (select jsonb_build_object('id', c.id, 'name', c.name,
                                           'is_invitation', c.is_invitation)
                   from public.ticket_categories c where c.id = v_ticket.category_id),
    'event', (select jsonb_build_object('id', e.id, 'title', e.title, 'status', e.status,
                                        'starts_at', e.starts_at)
                from public.events e where e.id = v_ticket.event_id),
    'organization', (select jsonb_build_object('id', o.id, 'name', o.name)
                       from public.events e join public.organizations o on o.id = e.organization_id
                      where e.id = v_ticket.event_id),
    'deliveries', coalesce((
      select jsonb_agg(jsonb_build_object('channel', d.channel, 'sent_at', d.sent_at)
                       order by d.sent_at desc, d.id desc)
        from (select * from public.ticket_deliveries d where d.ticket_id = v_ticket.id
               order by d.sent_at desc, d.id desc limit 10) d), '[]'::jsonb),
    'actions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'action', a.action, 'at', a.created_at, 'reason', a.reason,
               'by', coalesce(p.display_name, '—')) order by a.created_at desc, a.id desc)
        from (select * from private.admin_action_log l
               where l.target_id = v_ticket.id
               order by l.created_at desc, l.id desc limit 20) a
        left join public.profiles p on p.id = a.actor_id), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_ticket_detail(uuid) from public, anon;
grant execute on function public.admin_ticket_detail(uuid) to authenticated;

create function public.admin_revoke_ticket(p_ticket_id uuid, p_reason text, p_notify boolean default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_ticket public.tickets%rowtype;
  v_event public.events%rowtype;
begin
  perform private.require_admin('tickets');
  select * into v_ticket from public.tickets t where t.id = p_ticket_id for update;
  if not found then
    raise exception 'ticket_not_found' using errcode = 'P0002', detail = 'Ticket introuvable.';
  end if;
  if v_ticket.status <> 'issued' then
    raise exception 'ticket_not_revocable'
      using errcode = '55000', detail = 'Seul un ticket valable peut être annulé.';
  end if;
  select * into v_event from public.events e where e.id = v_ticket.event_id;
  update public.tickets t set status = 'revoked', revoked_at = now(), revoked_by = auth.uid()
   where t.id = p_ticket_id;
  perform private.log_admin_action('admin.ticket_revoked', 'ticket', p_ticket_id, v_reason,
    '{}'::jsonb, v_event.organization_id);
  if v_ticket.holder_user_id is not null and private.should_notify(p_notify) then
    perform private.notify_user(v_ticket.holder_user_id, 'Ticket annulé', 'Ticket cancelled',
      'Votre ticket ' || v_ticket.public_reference || ' (« ' || v_event.title
        || ' ») a été annulé. Motif : ' || v_reason,
      'Your ticket ' || v_ticket.public_reference || ' (“' || v_event.title
        || '”) was cancelled. Reason: ' || v_reason,
      '/portefeuille');
  end if;
end;
$$;
revoke all on function public.admin_revoke_ticket(uuid, text, boolean) from public, anon;
grant execute on function public.admin_revoke_ticket(uuid, text, boolean) to authenticated;

create function public.admin_set_ticket_holder(
  p_ticket_id uuid,
  p_name text,
  p_phone text,
  p_email text,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_ticket public.tickets%rowtype;
  v_holder record;
  v_org uuid;
begin
  perform private.require_admin('tickets');
  select * into v_ticket from public.tickets t where t.id = p_ticket_id for update;
  if not found then
    raise exception 'ticket_not_found' using errcode = 'P0002', detail = 'Ticket introuvable.';
  end if;
  if v_ticket.status <> 'issued' then
    raise exception 'ticket_not_editable'
      using errcode = '55000',
            detail = 'Seul un ticket valable, pas encore utilisé, peut changer de titulaire.';
  end if;
  select * into v_holder from private.check_holder(p_name, p_phone, p_email, null);
  update public.tickets t
     set holder_name = v_holder.name, holder_phone = v_holder.phone, holder_email = v_holder.email
   where t.id = p_ticket_id;
  select e.organization_id into v_org from public.events e where e.id = v_ticket.event_id;
  -- Journal : quels champs ont changé, jamais leur valeur.
  perform private.log_admin_action('admin.ticket_holder_updated', 'ticket', p_ticket_id, v_reason,
    jsonb_build_object(
      'name', v_holder.name is distinct from v_ticket.holder_name,
      'phone', v_holder.phone is distinct from v_ticket.holder_phone,
      'email', v_holder.email is distinct from v_ticket.holder_email), v_org);
  return jsonb_build_object('holder_name', v_holder.name, 'holder_phone', v_holder.phone,
                            'holder_email', v_holder.email);
end;
$$;
revoke all on function public.admin_set_ticket_holder(uuid, text, text, text, text) from public, anon;
grant execute on function public.admin_set_ticket_holder(uuid, text, text, text, text) to authenticated;

-- Tickets anonymes émis par l'administrateur (réglage de la console). Ils
-- rejoignent la liste du promoteur, en un lot ; leur QR n'est pas renvoyé.
create function public.admin_issue_tickets(
  p_event_id uuid,
  p_category_id uuid,
  p_quantity integer,
  p_reason text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_reason text := private.clean_admin_reason(p_reason);
  v_event public.events%rowtype;
  v_count integer;
  v_batch integer;
begin
  perform private.require_admin('tickets');
  if not private.console_setting_bool('admin_issue_tickets') then
    raise exception 'admin_issue_disabled'
      using errcode = '55000',
            detail = 'Activez « Émettre des tickets à la place d''un promoteur » dans les réglages.';
  end if;
  if p_quantity is null or p_quantity not between 1 and 1000 then
    raise exception 'issue_quantity_invalid'
      using errcode = '22023', detail = 'De 1 à 1 000 tickets.';
  end if;
  v_event := private.lock_console_event(p_event_id);
  if not exists (select 1 from public.ticket_categories c
                  where c.id = p_category_id and c.event_id = p_event_id) then
    raise exception 'category_not_found'
      using errcode = 'P0002', detail = 'Catégorie introuvable.';
  end if;
  select count(*) into v_count
    from private.issue_ticket_rows(
      p_event_id,
      (select jsonb_agg(jsonb_build_object('category_id', p_category_id))
         from generate_series(1, p_quantity)));
  select max(b.number) into v_batch from public.ticket_batches b where b.event_id = p_event_id;
  perform private.log_admin_action('admin.tickets_issued', 'event', p_event_id, v_reason,
    jsonb_build_object('count', v_count, 'category', p_category_id, 'batch', v_batch),
    v_event.organization_id);
  return jsonb_build_object('count', v_count, 'batch', v_batch);
end;
$$;
revoke all on function public.admin_issue_tickets(uuid, uuid, integer, text) from public, anon;
grant execute on function public.admin_issue_tickets(uuid, uuid, integer, text) to authenticated;
