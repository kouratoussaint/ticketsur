-- =============================================================================
-- Tikéo — Migration 4600 : réglages de la structure (lot 4-7b, ADR 0035)
-- =============================================================================
-- Un réglage par structure, lu par tous les téléphones de l'équipe :
--   * message d'envoi personnalisé d'un ticket et d'une invitation (WhatsApp,
--     SMS, e-mail), avec des champs à insérer remplis par l'app ; le jeton du
--     QR n'y figure jamais (aucun champ ne le permet) ;
--   * valeurs par défaut d'un nouvel événement : fuseau, ville, type,
--     catégories proposées (nom, quota, prix indicatif, invitation), portes.
--
--   organization_settings (fermée à l'API)
--   organization_settings(structure)            : lecture, propriétaire et gestionnaires
--   update_organization_settings(structure, …)  : écriture, propriétaire et gestionnaires
--   apply_event_defaults(événement)              : ajoute les catégories et portes
--                                                  proposées absentes de l'événement
-- Journal : seulement des indicateurs et des nombres, jamais le texte du message.
--
-- Erreurs (MESSAGE = code stable, DETAIL = texte lisible) :
--   42501 organization_not_found
--   22023 settings_message_invalid | settings_timezone_invalid | settings_city_invalid
--         | settings_kind_invalid | settings_categories_invalid | settings_checkpoints_invalid
-- =============================================================================

create table public.organization_settings (
  organization_id uuid primary key references public.organizations (id) on delete cascade,
  ticket_message text check (ticket_message is null or char_length(ticket_message) between 1 and 600),
  invitation_message text
    check (invitation_message is null or char_length(invitation_message) between 1 and 600),
  default_timezone text,
  default_city text check (default_city is null or char_length(default_city) between 2 and 80),
  default_kind public.event_kind,
  default_categories jsonb not null default '[]'::jsonb
    check (jsonb_typeof(default_categories) = 'array' and jsonb_array_length(default_categories) <= 10),
  default_checkpoints jsonb not null default '[]'::jsonb
    check (jsonb_typeof(default_checkpoints) = 'array' and jsonb_array_length(default_checkpoints) <= 10),
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.organization_settings enable row level security;
revoke all on public.organization_settings from anon, authenticated;

-- -----------------------------------------------------------------------------
-- Lecture
-- -----------------------------------------------------------------------------
create function public.organization_settings(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_row public.organization_settings%rowtype;
begin
  if auth.uid() is null
     or not private.has_org_role(p_organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'organization_not_found'
      using errcode = '42501', detail = 'Structure introuvable ou droits insuffisants.';
  end if;
  select * into v_row from public.organization_settings s
   where s.organization_id = p_organization_id;
  return jsonb_build_object(
    'ticket_message', v_row.ticket_message,
    'invitation_message', v_row.invitation_message,
    'default_timezone', v_row.default_timezone,
    'default_city', v_row.default_city,
    'default_kind', v_row.default_kind,
    'default_categories', coalesce(v_row.default_categories, '[]'::jsonb),
    'default_checkpoints', coalesce(v_row.default_checkpoints, '[]'::jsonb),
    'updated_at', v_row.updated_at);
end;
$$;
revoke all on function public.organization_settings(uuid) from public, anon;
grant execute on function public.organization_settings(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Écriture (remplace tout le réglage)
-- -----------------------------------------------------------------------------
create function public.update_organization_settings(
  p_organization_id uuid,
  p_ticket_message text,
  p_invitation_message text,
  p_default_timezone text,
  p_default_city text,
  p_default_kind text,
  p_default_categories jsonb,
  p_default_checkpoints jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_ticket text := nullif(btrim(coalesce(p_ticket_message, '')), '');
  v_invitation text := nullif(btrim(coalesce(p_invitation_message, '')), '');
  v_city text := nullif(private.normalize_text(p_default_city), '');
  v_zone text := nullif(btrim(coalesce(p_default_timezone, '')), '');
  v_kind public.event_kind;
  v_categories jsonb := '[]'::jsonb;
  v_checkpoints jsonb := '[]'::jsonb;
  v_item jsonb;
  v_name text;
  v_capacity integer;
  v_price integer;
  v_invite boolean;
  v_names text[] := '{}';
begin
  if v_actor is null
     or not private.has_org_role(p_organization_id,
                                 array['owner','manager']::public.member_role[]) then
    raise exception 'organization_not_found'
      using errcode = '42501', detail = 'Structure introuvable ou droits insuffisants.';
  end if;

  if (v_ticket is not null and char_length(v_ticket) > 600)
     or (v_invitation is not null and char_length(v_invitation) > 600) then
    raise exception 'settings_message_invalid'
      using errcode = '22023', detail = 'Message de 600 caractères au plus.';
  end if;
  if v_zone is not null
     and not exists (select 1 from pg_catalog.pg_timezone_names z where z.name = v_zone) then
    raise exception 'settings_timezone_invalid'
      using errcode = '22023', detail = 'Fuseau horaire inconnu.';
  end if;
  if v_city is not null and char_length(v_city) not between 2 and 80 then
    raise exception 'settings_city_invalid'
      using errcode = '22023', detail = 'Ville de 2 à 80 caractères.';
  end if;
  if nullif(btrim(coalesce(p_default_kind, '')), '') is not null then
    if not exists (select 1 from pg_catalog.pg_enum e
                    where e.enumtypid = 'public.event_kind'::regtype
                      and e.enumlabel = btrim(p_default_kind)) then
      raise exception 'settings_kind_invalid'
        using errcode = '22023', detail = 'Type d''événement inconnu.';
    end if;
    v_kind := btrim(p_default_kind)::public.event_kind;
  end if;

  -- Catégories proposées : 10 au plus, noms distincts, quota et prix valides.
  if p_default_categories is not null then
    if jsonb_typeof(p_default_categories) <> 'array'
       or jsonb_array_length(p_default_categories) > 10 then
      raise exception 'settings_categories_invalid'
        using errcode = '22023', detail = '10 catégories au plus.';
    end if;
    for v_item in select value from jsonb_array_elements(p_default_categories) loop
      v_name := private.normalize_text(v_item->>'name');
      begin
        v_capacity := nullif(v_item->>'capacity', '')::integer;
        v_price := nullif(v_item->>'price', '')::integer;
        v_invite := coalesce((v_item->>'invitation')::boolean, false);
      exception when others then
        raise exception 'settings_categories_invalid'
          using errcode = '22023', detail = 'Quota ou prix invalide.';
      end;
      if jsonb_typeof(v_item) <> 'object'
         or v_name is null or char_length(v_name) not between 1 and 60
         or lower(v_name) = any (v_names)
         or (v_capacity is not null and v_capacity not between 1 and 1000000)
         or (v_price is not null and v_price not between 0 and 10000000) then
        raise exception 'settings_categories_invalid'
          using errcode = '22023',
                detail = 'Catégorie : nom de 1 à 60 caractères, unique ; quota de 1 à 1 000 000 ; '
                         'prix de 0 à 10 000 000 FCFA.';
      end if;
      v_names := v_names || lower(v_name);
      v_categories := v_categories || jsonb_build_array(jsonb_build_object(
        'name', v_name, 'capacity', v_capacity, 'price', v_price,
        'invitation', v_invite));
    end loop;
  end if;

  -- Portes proposées : 10 au plus, noms distincts.
  v_names := '{}';
  if p_default_checkpoints is not null then
    if jsonb_typeof(p_default_checkpoints) <> 'array'
       or jsonb_array_length(p_default_checkpoints) > 10 then
      raise exception 'settings_checkpoints_invalid'
        using errcode = '22023', detail = '10 portes au plus.';
    end if;
    for v_item in select value from jsonb_array_elements(p_default_checkpoints) loop
      v_name := case when jsonb_typeof(v_item) = 'string'
                     then private.normalize_text(v_item #>> '{}') end;
      if v_name is null or char_length(v_name) not between 1 and 60
         or lower(v_name) = any (v_names) then
        raise exception 'settings_checkpoints_invalid'
          using errcode = '22023', detail = 'Porte : nom de 1 à 60 caractères, unique.';
      end if;
      v_names := v_names || lower(v_name);
      v_checkpoints := v_checkpoints || to_jsonb(v_name);
    end loop;
  end if;

  insert into public.organization_settings as s
    (organization_id, ticket_message, invitation_message, default_timezone, default_city,
     default_kind, default_categories, default_checkpoints, updated_by, updated_at)
  values (p_organization_id, v_ticket, v_invitation, v_zone, v_city, v_kind, v_categories,
          v_checkpoints, v_actor, now())
  on conflict (organization_id) do update
     set ticket_message = excluded.ticket_message,
         invitation_message = excluded.invitation_message,
         default_timezone = excluded.default_timezone,
         default_city = excluded.default_city,
         default_kind = excluded.default_kind,
         default_categories = excluded.default_categories,
         default_checkpoints = excluded.default_checkpoints,
         updated_by = excluded.updated_by,
         updated_at = excluded.updated_at;

  -- Journal : indicateurs et nombres seulement, jamais le texte des messages.
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, v_actor, 'organization.settings_updated', 'organization',
          p_organization_id,
          jsonb_build_object('ticket_message', v_ticket is not null,
                             'invitation_message', v_invitation is not null,
                             'categories', jsonb_array_length(v_categories),
                             'checkpoints', jsonb_array_length(v_checkpoints)));
  return public.organization_settings(p_organization_id);
end;
$$;
revoke all on function public.update_organization_settings(uuid, text, text, text, text, text, jsonb, jsonb)
  from public, anon;
grant execute on function public.update_organization_settings(uuid, text, text, text, text, text, jsonb, jsonb)
  to authenticated;

-- -----------------------------------------------------------------------------
-- Catégories et portes proposées ajoutées à un événement
-- -----------------------------------------------------------------------------
-- N'ajoute que celles dont le nom n'existe pas encore dans l'événement.
create function public.apply_event_defaults(p_event_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events%rowtype;
  v_settings public.organization_settings%rowtype;
  v_categories integer := 0;
  v_checkpoints integer := 0;
begin
  v_event := private.lock_configurable_event(p_event_id);
  select * into v_settings from public.organization_settings s
   where s.organization_id = v_event.organization_id;
  if not found then
    return jsonb_build_object('categories', 0, 'checkpoints', 0);
  end if;

  with added as (
    insert into public.ticket_categories (event_id, name, capacity, indicative_price, is_invitation)
    select p_event_id, d->>'name', nullif(d->>'capacity', '')::integer,
           nullif(d->>'price', '')::integer, coalesce((d->>'invitation')::boolean, false)
      from jsonb_array_elements(v_settings.default_categories) d
     where not exists (select 1 from public.ticket_categories c
                        where c.event_id = p_event_id and lower(c.name) = lower(d->>'name'))
    returning 1)
  select count(*) into v_categories from added;

  with added as (
    insert into public.checkpoints (event_id, name)
    select p_event_id, d #>> '{}'
      from jsonb_array_elements(v_settings.default_checkpoints) d
     where not exists (select 1 from public.checkpoints c
                        where c.event_id = p_event_id and lower(c.name) = lower(d #>> '{}'))
    returning 1)
  select count(*) into v_checkpoints from added;

  if v_categories + v_checkpoints > 0 then
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_event.organization_id, auth.uid(), 'event.defaults_applied', 'event', p_event_id,
            jsonb_build_object('categories', v_categories, 'checkpoints', v_checkpoints));
  end if;
  return jsonb_build_object('categories', v_categories, 'checkpoints', v_checkpoints);
end;
$$;
revoke all on function public.apply_event_defaults(uuid) from public, anon;
grant execute on function public.apply_event_defaults(uuid) to authenticated;
