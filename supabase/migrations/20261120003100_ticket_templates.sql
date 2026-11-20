-- =============================================================================
-- Tikéo — Modèles de tickets (lot 4-4a, ADR 0022)
-- =============================================================================
-- * events.tagline : accroche facultative (60 caractères au plus).
-- * tickets.event_number : numéro d'ordre dans l'événement (« N° 000123 »),
--   attribué à l'insertion sous le verrou de l'événement.
-- * ticket_category_templates : un modèle par catégorie, intégré (thème 1 à
--   12) ou importé (image du bucket event-covers, dossier de l'événement,
--   QR et référence placés en proportions). Sans ligne : thème proposé par
--   l'application selon le type d'événement.
-- Le modèle n'est qu'un fond : format du QR et validation inchangés.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Accroche
-- -----------------------------------------------------------------------------
alter table public.events add column tagline text
  check (tagline is null or char_length(tagline) between 1 and 60);

create function public.set_event_tagline(p_event_id uuid, p_tagline text)
returns public.events
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_event public.events%rowtype;
  v_tagline text := nullif(btrim(coalesce(p_tagline, '')), '');
begin
  v_event := private.lock_managed_event(p_event_id);
  if v_event.status in ('closed', 'archived', 'cancelled') then
    raise exception 'event_locked'
      using errcode = '55000', detail = 'Événement clôturé, annulé ou archivé.';
  end if;
  if v_tagline is not null and char_length(v_tagline) > 60 then
    raise exception 'event_tagline_invalid'
      using errcode = '22023', detail = 'Accroche de 60 caractères au plus.';
  end if;
  if v_event.tagline is not distinct from v_tagline then
    return v_event;
  end if;
  update public.events e set tagline = v_tagline, updated_at = now()
   where e.id = p_event_id
  returning * into v_event;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, v_actor, 'event.updated', 'event', v_event.id,
          jsonb_build_object('fields', jsonb_build_array('tagline')));
  return v_event;
end;
$$;
revoke all on function public.set_event_tagline(uuid, text) from public, anon;
grant execute on function public.set_event_tagline(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Numéro d'ordre des tickets
-- -----------------------------------------------------------------------------
alter table public.tickets add column event_number integer;

update public.tickets t set event_number = n.rn
  from (select t2.id,
               row_number() over (partition by t2.event_id order by t2.issued_at, t2.id) as rn
          from public.tickets t2) n
 where n.id = t.id;

alter table public.tickets alter column event_number set not null;
alter table public.tickets
  add constraint tickets_event_number_unique unique (event_id, event_number);

-- Attribution à l'insertion. Le verrou de l'événement (déjà pris par
-- private.issue_ticket_rows) sérialise les émissions concurrentes.
create function private.assign_ticket_number()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform 1 from public.events e where e.id = new.event_id for update;
  select coalesce(max(t.event_number), 0) + 1 into new.event_number
    from public.tickets t where t.event_id = new.event_id;
  return new;
end;
$$;
revoke all on function private.assign_ticket_number() from public, anon, authenticated;
create trigger tickets_event_number
  before insert on public.tickets
  for each row execute function private.assign_ticket_number();

-- -----------------------------------------------------------------------------
-- Modèles par catégorie
-- -----------------------------------------------------------------------------
create table public.ticket_category_templates (
  category_id uuid primary key references public.ticket_categories (id) on delete cascade,
  kind text not null check (kind in ('builtin', 'custom')),
  builtin_theme smallint check (builtin_theme between 1 and 12),
  single_font_title boolean not null default false,
  image_path text,
  image_width integer check (image_width between 200 and 6000),
  image_height integer check (image_height between 100 and 6000),
  -- Proportions : x et la référence en largeur, y et la taille du QR en
  -- hauteur de l'image.
  qr_x real check (qr_x between 0 and 1),
  qr_y real check (qr_y between 0 and 1),
  qr_size real check (qr_size between 0.35 and 1),
  ref_x real check (ref_x between 0 and 1),
  ref_y real check (ref_y between 0 and 1),
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now(),
  check (
    (kind = 'builtin' and builtin_theme is not null and image_path is null)
    or (kind = 'custom' and builtin_theme is null and image_path is not null
        and image_width is not null and image_height is not null
        and qr_x is not null and qr_y is not null and qr_size is not null
        and ref_x is not null and ref_y is not null)
  )
);
alter table public.ticket_category_templates enable row level security;
revoke all on public.ticket_category_templates from anon, authenticated;

-- Modèles enregistrés des catégories d'un événement (propriétaires et
-- gestionnaires).
create function public.event_ticket_templates(p_event_id uuid)
returns table (
  category_id uuid, kind text, builtin_theme smallint, single_font_title boolean,
  image_path text, image_width integer, image_height integer,
  qr_x real, qr_y real, qr_size real, ref_x real, ref_y real
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
    select m.category_id, m.kind, m.builtin_theme, m.single_font_title,
           m.image_path, m.image_width, m.image_height,
           m.qr_x, m.qr_y, m.qr_size, m.ref_x, m.ref_y
      from public.ticket_category_templates m
      join public.ticket_categories c on c.id = m.category_id
     where c.event_id = p_event_id
     order by c.id;
end;
$$;
revoke all on function public.event_ticket_templates(uuid) from public, anon;
grant execute on function public.event_ticket_templates(uuid) to authenticated;

-- Enregistre (ou retire, p_template = null) le modèle d'une catégorie.
create function public.set_ticket_template(p_category_id uuid, p_template jsonb)
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
    insert into public.ticket_category_templates
      (category_id, kind, builtin_theme, single_font_title, updated_by, updated_at)
    values (p_category_id, 'builtin', v_theme,
            coalesce((p_template->>'single_font_title')::boolean, false), v_actor, now())
    on conflict (category_id) do update
      set kind = 'builtin', builtin_theme = excluded.builtin_theme,
          single_font_title = excluded.single_font_title,
          image_path = null, image_width = null, image_height = null,
          qr_x = null, qr_y = null, qr_size = null, ref_x = null, ref_y = null,
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
    -- Le QR (carré de côté qr_size × hauteur) reste dans l'image.
    if v_qr_y + v_qr_size > 1.0001 or v_qr_x + v_qr_size * v_h / v_w > 1.0001 then
      raise exception 'template_invalid'
        using errcode = '22023', detail = 'Le QR dépasse du ticket.';
    end if;
    insert into public.ticket_category_templates
      (category_id, kind, single_font_title, image_path, image_width, image_height,
       qr_x, qr_y, qr_size, ref_x, ref_y, updated_by, updated_at)
    values (p_category_id, 'custom', false, v_path, v_w, v_h,
            v_qr_x, v_qr_y, v_qr_size, v_ref_x, v_ref_y, v_actor, now())
    on conflict (category_id) do update
      set kind = 'custom', builtin_theme = null, single_font_title = false,
          image_path = excluded.image_path, image_width = excluded.image_width,
          image_height = excluded.image_height, qr_x = excluded.qr_x, qr_y = excluded.qr_y,
          qr_size = excluded.qr_size, ref_x = excluded.ref_x, ref_y = excluded.ref_y,
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
revoke all on function public.set_ticket_template(uuid, jsonb) from public, anon;
grant execute on function public.set_ticket_template(uuid, jsonb) to authenticated;

-- Catégorie et numéro d'ordre de tickets à dessiner (propriétaires et
-- gestionnaires ; les autres identifiants sont ignorés).
create function public.ticket_art_info(p_ticket_ids uuid[])
returns table (ticket_id uuid, category_id uuid, event_number integer)
language sql
stable
security definer
set search_path = ''
as $$
  select t.id, t.category_id, t.event_number
    from public.tickets t
    join public.events e on e.id = t.event_id
   where t.id = any (coalesce(p_ticket_ids, '{}'))
     and cardinality(p_ticket_ids) <= 500
     and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
   order by t.event_number
$$;
revoke all on function public.ticket_art_info(uuid[]) from public, anon;
grant execute on function public.ticket_art_info(uuid[]) to authenticated;
