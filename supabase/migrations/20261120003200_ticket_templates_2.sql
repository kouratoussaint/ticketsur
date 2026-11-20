-- =============================================================================
-- Tikéo — Modèles de tickets, suite (lot 4-4a PR 2, ADR 0022)
-- =============================================================================
-- * Titulaire positionnable sur un design importé (holder_x, holder_y).
-- * Cadrage de la photo de couverture sur un thème intégré (cover_x,
--   cover_y : point gardé visible ; cover_zoom : 1 à 3).
-- * « Mes tickets » : numéro, accroche, logo de la structure et modèle de
--   la catégorie, pour dessiner le ticket chez son titulaire (sans réseau
--   grâce au cache de l'appareil).
-- * Duplication d'un événement : accroche et thèmes intégrés recopiés (les
--   designs importés sont recopiés par l'application, avec leur image).
-- =============================================================================

alter table public.ticket_category_templates
  add column holder_x real check (holder_x between 0 and 1),
  add column holder_y real check (holder_y between 0 and 1),
  add column cover_x real check (cover_x between 0 and 1),
  add column cover_y real check (cover_y between 0 and 1),
  add column cover_zoom real check (cover_zoom between 1 and 3);

-- Modèle d'une catégorie en JSON (null sans modèle enregistré).
create function private.template_json(p_category_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
           'kind', m.kind, 'builtin_theme', m.builtin_theme,
           'single_font_title', m.single_font_title,
           'image_path', m.image_path, 'image_width', m.image_width,
           'image_height', m.image_height, 'qr_x', m.qr_x, 'qr_y', m.qr_y,
           'qr_size', m.qr_size, 'ref_x', m.ref_x, 'ref_y', m.ref_y,
           'holder_x', m.holder_x, 'holder_y', m.holder_y,
           'cover_x', m.cover_x, 'cover_y', m.cover_y, 'cover_zoom', m.cover_zoom))
    from public.ticket_category_templates m
   where m.category_id = p_category_id
$$;
revoke all on function private.template_json(uuid) from public, anon, authenticated;

drop function public.event_ticket_templates(uuid);
create function public.event_ticket_templates(p_event_id uuid)
returns table (category_id uuid, template jsonb)
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
    select c.id, private.template_json(c.id)
      from public.ticket_categories c
     where c.event_id = p_event_id
       and exists (select 1 from public.ticket_category_templates m where m.category_id = c.id)
     order by c.id;
end;
$$;
revoke all on function public.event_ticket_templates(uuid) from public, anon;
grant execute on function public.event_ticket_templates(uuid) to authenticated;

-- Proportion facultative : null, ou un nombre dans [p_min, p_max].
create function private.template_share(p_template jsonb, p_key text, p_min real, p_max real)
returns real
language plpgsql
immutable
set search_path = ''
as $$
declare
  v real;
begin
  if p_template->p_key is null or jsonb_typeof(p_template->p_key) = 'null' then
    return null;
  end if;
  begin
    v := (p_template->>p_key)::real;
  exception when others then
    raise exception 'template_invalid' using errcode = '22023', detail = 'Placement invalide.';
  end;
  if v is null or v < p_min or v > p_max then
    raise exception 'template_invalid' using errcode = '22023', detail = 'Placement invalide.';
  end if;
  return v;
end;
$$;
revoke all on function private.template_share(jsonb, text, real, real) from public, anon, authenticated;

-- Enregistre (ou retire, p_template = null) le modèle d'une catégorie.
create or replace function public.set_ticket_template(p_category_id uuid, p_template jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_event_id uuid;
  v_kind text := p_template->>'kind';
  v_theme integer;
  v_path text;
  v_w integer;
  v_h integer;
  v_qr_x real;
  v_qr_y real;
  v_qr_size real;
  v_ref_x real;
  v_ref_y real;
  v_holder_x real;
  v_holder_y real;
  v_cover_x real;
  v_cover_y real;
  v_cover_zoom real;
begin
  select c.event_id into v_event_id from public.ticket_categories c where c.id = p_category_id;
  if v_event_id is null then
    raise exception 'category_not_found'
      using errcode = '42501', detail = 'Catégorie introuvable ou droits insuffisants.';
  end if;
  v_event := private.lock_managed_event(v_event_id);
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;

  if p_template is null then
    delete from public.ticket_category_templates m where m.category_id = p_category_id;
    v_kind := 'default';
  elsif v_kind = 'builtin' then
    begin
      v_theme := (p_template->>'builtin_theme')::integer;
    exception when others then
      v_theme := null;
    end;
    if v_theme is null or v_theme not between 1 and 12 then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Modèle inconnu.';
    end if;
    v_cover_x := private.template_share(p_template, 'cover_x', 0, 1);
    v_cover_y := private.template_share(p_template, 'cover_y', 0, 1);
    v_cover_zoom := private.template_share(p_template, 'cover_zoom', 1, 3);
    insert into public.ticket_category_templates
      (category_id, kind, builtin_theme, single_font_title, cover_x, cover_y, cover_zoom,
       updated_by, updated_at)
    values (p_category_id, 'builtin', v_theme,
            coalesce((p_template->>'single_font_title')::boolean, false),
            v_cover_x, v_cover_y, v_cover_zoom, v_actor, now())
    on conflict (category_id) do update
      set kind = 'builtin', builtin_theme = excluded.builtin_theme,
          single_font_title = excluded.single_font_title,
          cover_x = excluded.cover_x, cover_y = excluded.cover_y,
          cover_zoom = excluded.cover_zoom,
          image_path = null, image_width = null, image_height = null,
          qr_x = null, qr_y = null, qr_size = null, ref_x = null, ref_y = null,
          holder_x = null, holder_y = null,
          updated_by = v_actor, updated_at = now();
  elsif v_kind = 'custom' then
    v_path := p_template->>'image_path';
    begin
      v_w := (p_template->>'image_width')::integer;
      v_h := (p_template->>'image_height')::integer;
      v_qr_x := (p_template->>'qr_x')::real;
      v_qr_y := (p_template->>'qr_y')::real;
      v_qr_size := (p_template->>'qr_size')::real;
      v_ref_x := (p_template->>'ref_x')::real;
      v_ref_y := (p_template->>'ref_y')::real;
    exception when others then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Placement invalide.';
    end;
    v_holder_x := private.template_share(p_template, 'holder_x', 0, 1);
    v_holder_y := private.template_share(p_template, 'holder_y', 0, 1);
    if (v_holder_x is null) <> (v_holder_y is null) then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Placement invalide.';
    end if;
    if v_path is null
       or split_part(v_path, '/', 1) <> v_event.organization_id::text
       or split_part(v_path, '/', 2) <> v_event.id::text
       or not private.can_manage_event_cover(v_path)
       or not exists (select 1 from storage.objects o
                       where o.bucket_id = 'event-covers' and o.name = v_path) then
      raise exception 'template_image_invalid'
        using errcode = '22023', detail = 'Image du modèle introuvable ou mal placée.';
    end if;
    if v_w is null or v_h is null or v_w not between 200 and 6000 or v_h not between 100 and 6000
       or v_qr_x is null or v_qr_y is null or v_qr_size is null
       or v_ref_x is null or v_ref_y is null
       or v_qr_x < 0 or v_qr_y < 0 or v_ref_x not between 0 and 1 or v_ref_y not between 0 and 1 then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Placement invalide.';
    end if;
    if v_qr_size < 0.35 then
      raise exception 'template_qr_too_small'
        using errcode = '22023', detail = 'Le QR doit occuper au moins 35 % de la hauteur du ticket.';
    end if;
    if v_qr_y + v_qr_size > 1.0001 or v_qr_x + v_qr_size * v_h / v_w > 1.0001 then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Le QR dépasse du ticket.';
    end if;
    insert into public.ticket_category_templates
      (category_id, kind, single_font_title, image_path, image_width, image_height,
       qr_x, qr_y, qr_size, ref_x, ref_y, holder_x, holder_y, updated_by, updated_at)
    values (p_category_id, 'custom', false, v_path, v_w, v_h,
            v_qr_x, v_qr_y, v_qr_size, v_ref_x, v_ref_y, v_holder_x, v_holder_y, v_actor, now())
    on conflict (category_id) do update
      set kind = 'custom', builtin_theme = null, single_font_title = false,
          image_path = excluded.image_path, image_width = excluded.image_width,
          image_height = excluded.image_height, qr_x = excluded.qr_x, qr_y = excluded.qr_y,
          qr_size = excluded.qr_size, ref_x = excluded.ref_x, ref_y = excluded.ref_y,
          holder_x = excluded.holder_x, holder_y = excluded.holder_y,
          cover_x = null, cover_y = null, cover_zoom = null,
          updated_by = v_actor, updated_at = now();
  else
    raise exception 'template_invalid'
      using errcode = '22023', detail = 'Modèle inconnu.';
  end if;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'ticket_template.updated', 'event', v_event.id,
          jsonb_build_object('kind', v_kind));
end;
$$;

-- « Mes tickets » : de quoi dessiner le ticket chez son titulaire.
drop function public.my_tickets();
create function public.my_tickets()
returns table (
  ticket_id uuid,
  public_reference text,
  status public.ticket_status,
  redeemed_at timestamptz,
  category_name text,
  is_invitation boolean,
  holder_name text,
  qr_token text,
  event_id uuid,
  event_title text,
  event_status public.event_status,
  starts_at timestamptz,
  ends_at timestamptz,
  timezone text,
  venue text,
  city text,
  kind public.event_kind,
  cover_path text,
  organization_name text,
  event_number integer,
  tagline text,
  organization_logo_path text,
  template jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_key text := private.vault_secret('ticketsur_qr_encryption_key');
begin
  return query
    select t.id, t.public_reference, t.status, t.redeemed_at, c.name, c.is_invitation,
           t.holder_name,
           case when t.status = 'issued'
                then extensions.pgp_sym_decrypt(s.token_ciphertext, v_key) end,
           e.id, e.title, e.status, e.starts_at, e.ends_at, e.timezone, e.venue, e.city,
           e.kind, e.cover_path, o.name,
           t.event_number, e.tagline, o.logo_path, private.template_json(c.id)
      from public.tickets t
      join public.events e on e.id = t.event_id
      join public.organizations o on o.id = e.organization_id
      join public.ticket_categories c on c.id = t.category_id
      join private.ticket_secrets s on s.ticket_id = t.id
     where t.holder_user_id = v_actor
     order by (e.ends_at < now()), e.starts_at, t.public_reference
     limit 200;
end;
$$;
revoke all on function public.my_tickets() from public, anon;
grant execute on function public.my_tickets() to authenticated;

-- Duplication : accroche et thèmes intégrés recopiés.
create or replace function public.duplicate_event(
  p_event_id uuid,
  p_title text,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_source public.events%rowtype;
  v_title text := private.normalize_text(p_title);
  v_id uuid;
begin
  select * into v_source from public.events e where e.id = p_event_id;
  if v_actor is null or not found
     or not private.has_org_role(v_source.organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  perform private.check_event_fields(v_title, v_source.venue, v_source.timezone,
                                     p_starts_at, p_ends_at, v_source.capacity);

  insert into public.events (organization_id, title, venue, timezone, starts_at, ends_at,
                             capacity, status, created_by, city, country_code, venue_address,
                             latitude, longitude, description, kind, is_public, tagline)
  values (v_source.organization_id, v_title, v_source.venue, v_source.timezone, p_starts_at,
          p_ends_at, v_source.capacity, 'draft', v_actor, v_source.city, v_source.country_code,
          v_source.venue_address, v_source.latitude, v_source.longitude, v_source.description,
          v_source.kind, v_source.is_public and v_source.public_blocked_at is null,
          v_source.tagline)
  returning id into v_id;

  insert into public.ticket_categories (event_id, name, capacity, is_invitation, indicative_price)
  select v_id, c.name, c.capacity, c.is_invitation, c.indicative_price
    from public.ticket_categories c where c.event_id = p_event_id;

  -- Thèmes intégrés, catégorie retrouvée par son nom (unique par événement).
  insert into public.ticket_category_templates
    (category_id, kind, builtin_theme, single_font_title, cover_x, cover_y, cover_zoom,
     updated_by, updated_at)
  select n.id, 'builtin', m.builtin_theme, m.single_font_title, m.cover_x, m.cover_y,
         m.cover_zoom, v_actor, now()
    from public.ticket_category_templates m
    join public.ticket_categories o on o.id = m.category_id and o.event_id = p_event_id
    join public.ticket_categories n on n.event_id = v_id and n.name = o.name
   where m.kind = 'builtin';

  insert into public.checkpoints (event_id, name, active)
  select v_id, c.name, c.active from public.checkpoints c where c.event_id = p_event_id;

  -- Affectations actives, porte retrouvée par son nom.
  insert into public.event_assignments (event_id, user_id, checkpoint_id, active)
  select v_id, a.user_id, n.id, true
    from public.event_assignments a
    left join public.checkpoints o on o.id = a.checkpoint_id
    left join public.checkpoints n on n.event_id = v_id and n.name = o.name
   where a.event_id = p_event_id and a.active
  on conflict do nothing;

  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_source.organization_id, v_actor, 'event.duplicated', 'event', v_id,
          jsonb_build_object('source', p_event_id));
  return v_id;
end;
$$;
