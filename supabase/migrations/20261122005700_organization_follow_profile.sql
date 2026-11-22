-- =============================================================================
-- Tikéo — Structures : suivre, présentation et réseaux (améliorations n° 5
-- et 7 validées par Toussaint le 22/11/2026, ADR 0047)
-- =============================================================================
-- 1. Présentation publique d'une structure : un court texte et ses pages
--    Facebook, Instagram, TikTok, saisis par le propriétaire et affichés sur
--    sa page publique.
-- 2. Suivre une structure : un compte suit une structure active ; à la
--    première mise au catalogue d'un de ses événements, chaque abonné (hors
--    membres de la structure) reçoit une notification vers la fiche.
--    Aucune donnée personnelle dans le journal ; la liste des abonnés n'est
--    jamais exposée (seulement leur nombre).

-- -----------------------------------------------------------------------------
-- Présentation et réseaux
-- -----------------------------------------------------------------------------
alter table public.organizations
  add column public_description text
    check (public_description is null or char_length(public_description) between 1 and 600),
  add column facebook_url text check (facebook_url is null
    or facebook_url ~ '^https://([a-z0-9-]+\.)?(facebook\.com|fb\.com)/[^\s]{1,180}$'),
  add column instagram_url text check (instagram_url is null
    or instagram_url ~ '^https://([a-z0-9-]+\.)?instagram\.com/[^\s]{1,180}$'),
  add column tiktok_url text check (tiktok_url is null
    or tiktok_url ~ '^https://([a-z0-9-]+\.)?tiktok\.com/[^\s]{1,180}$');

create function public.set_organization_profile(
  p_organization_id uuid,
  p_description text,
  p_facebook_url text,
  p_instagram_url text,
  p_tiktok_url text
)
returns public.organizations
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_old public.organizations%rowtype;
  v_org public.organizations%rowtype;
  v_description text := nullif(btrim(p_description), '');
  v_facebook text := nullif(btrim(p_facebook_url), '');
  v_instagram text := nullif(btrim(p_instagram_url), '');
  v_tiktok text := nullif(btrim(p_tiktok_url), '');
begin
  v_old := private.lock_owned_organization(p_organization_id);
  if v_description is not null and char_length(v_description) > 600 then
    raise exception 'org_description_invalid'
      using errcode = '22023', detail = 'La présentation fait 600 caractères au plus.';
  end if;
  if v_facebook is not null
     and v_facebook !~ '^https://([a-z0-9-]+\.)?(facebook\.com|fb\.com)/[^\s]{1,180}$' then
    raise exception 'org_link_invalid'
      using errcode = '22023', detail = 'Lien Facebook invalide.';
  end if;
  if v_instagram is not null
     and v_instagram !~ '^https://([a-z0-9-]+\.)?instagram\.com/[^\s]{1,180}$' then
    raise exception 'org_link_invalid'
      using errcode = '22023', detail = 'Lien Instagram invalide.';
  end if;
  if v_tiktok is not null
     and v_tiktok !~ '^https://([a-z0-9-]+\.)?tiktok\.com/[^\s]{1,180}$' then
    raise exception 'org_link_invalid'
      using errcode = '22023', detail = 'Lien TikTok invalide.';
  end if;
  update public.organizations o
     set public_description = v_description, facebook_url = v_facebook,
         instagram_url = v_instagram, tiktok_url = v_tiktok, updated_at = now()
   where o.id = p_organization_id
  returning * into v_org;
  -- Journal : noms des champs modifiés seulement, jamais le contenu.
  if v_old.public_description is distinct from v_org.public_description
     or v_old.facebook_url is distinct from v_org.facebook_url
     or v_old.instagram_url is distinct from v_org.instagram_url
     or v_old.tiktok_url is distinct from v_org.tiktok_url then
    insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
    values (v_org.id, auth.uid(), 'organization.profile_updated', 'organization', v_org.id,
            jsonb_build_object('fields', to_jsonb(array_remove(array[
              case when v_old.public_description is distinct from v_org.public_description then 'description' end,
              case when v_old.facebook_url is distinct from v_org.facebook_url then 'facebook' end,
              case when v_old.instagram_url is distinct from v_org.instagram_url then 'instagram' end,
              case when v_old.tiktok_url is distinct from v_org.tiktok_url then 'tiktok' end
            ], null))));
  end if;
  return v_org;
end;
$$;
revoke all on function public.set_organization_profile(uuid, text, text, text, text) from public, anon;
grant execute on function public.set_organization_profile(uuid, text, text, text, text) to authenticated;

-- `my_organizations` : la présentation et les réseaux s'ajoutent (formulaire).
drop function public.my_organizations();
create function public.my_organizations()
returns table (
  id uuid, name text, slug text, role public.member_role,
  logo_path text, phone text, contact_email text, city text, public_phone text,
  public_description text, facebook_url text, instagram_url text, tiktok_url text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select o.id, o.name, o.slug, m.role, o.logo_path, o.phone, o.contact_email, o.city,
         o.public_phone, o.public_description, o.facebook_url, o.instagram_url, o.tiktok_url
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  where m.user_id = auth.uid()
    and m.active
    and o.status = 'active'
  order by o.created_at, o.name
$$;
revoke all on function public.my_organizations() from public, anon;
grant execute on function public.my_organizations() to authenticated;

-- -----------------------------------------------------------------------------
-- Suivre une structure
-- -----------------------------------------------------------------------------
create table public.organization_followers (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);
create index organization_followers_user on public.organization_followers (user_id);
alter table public.organization_followers enable row level security;
revoke all on public.organization_followers from anon, authenticated;

-- Suivre (vrai) ou ne plus suivre (faux) ; renvoie l'état et le nombre
-- d'abonnés. 300 structures suivies au plus par compte.
create function public.follow_organization(p_organization_id uuid, p_follow boolean)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
begin
  if p_follow then
    if not exists (select 1 from public.organizations o
                    where o.id = p_organization_id and o.status = 'active') then
      raise exception 'organization_not_found'
        using errcode = 'P0002', detail = 'Structure introuvable.';
    end if;
    if (select count(*) from public.organization_followers f where f.user_id = v_actor) >= 300
       and not exists (select 1 from public.organization_followers f
                        where f.user_id = v_actor and f.organization_id = p_organization_id) then
      raise exception 'follow_limit'
        using errcode = '54000', detail = 'Vous suivez déjà 300 structures.';
    end if;
    insert into public.organization_followers (organization_id, user_id)
    values (p_organization_id, v_actor)
    on conflict do nothing;
  else
    delete from public.organization_followers f
     where f.organization_id = p_organization_id and f.user_id = v_actor;
  end if;
  return jsonb_build_object(
    'following', coalesce(p_follow, false),
    'followers', (select count(*) from public.organization_followers f
                   where f.organization_id = p_organization_id));
end;
$$;
revoke all on function public.follow_organization(uuid, boolean) from public, anon;
grant execute on function public.follow_organization(uuid, boolean) to authenticated;

-- Structures suivies par le compte (actives), avec leurs événements à venir.
create function public.my_followed_organizations()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', o.id, 'name', o.name, 'city', o.city, 'logo_path', o.logo_path,
           'upcoming', (select count(*) from public.events e
                         where e.organization_id = o.id and private.is_listed(e)))
         order by o.name, o.id), '[]'::jsonb)
    from public.organization_followers f
    join public.organizations o on o.id = f.organization_id
   where f.user_id = auth.uid() and o.status = 'active'
$$;
revoke all on function public.my_followed_organizations() from public, anon;
grant execute on function public.my_followed_organizations() to authenticated;

-- Page publique : présentation, réseaux, nombre d'abonnés, « suivi » du compte.
create or replace function public.public_organization(p_organization_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org public.organizations%rowtype;
begin
  select * into v_org from public.organizations o
   where o.id = p_organization_id and o.status = 'active';
  if not found then
    raise exception 'organization_not_found'
      using errcode = 'P0002', detail = 'Structure introuvable.';
  end if;
  return jsonb_build_object(
    'id', v_org.id,
    'name', v_org.name,
    'city', v_org.city,
    'logo_path', v_org.logo_path,
    'public_phone', v_org.public_phone,
    'created_at', v_org.created_at,
    'description', v_org.public_description,
    'facebook_url', v_org.facebook_url,
    'instagram_url', v_org.instagram_url,
    'tiktok_url', v_org.tiktok_url,
    'followers', (select count(*) from public.organization_followers f
                   where f.organization_id = v_org.id),
    'following', auth.uid() is not null and exists (
                   select 1 from public.organization_followers f
                    where f.organization_id = v_org.id and f.user_id = auth.uid()),
    'past_events', (
      select count(*) from public.events e
       where e.organization_id = v_org.id
         and e.is_public and e.public_blocked_at is null
         and e.status in ('published', 'in_progress', 'closed', 'archived')
         and e.ends_at <= now()),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', e.id, 'title', e.title, 'kind', e.kind,
               'starts_at', e.starts_at, 'ends_at', e.ends_at, 'timezone', e.timezone,
               'venue', e.venue, 'city', e.city, 'cover_path', e.cover_path,
               'organization_name', v_org.name,
               'min_price', (select min(c.indicative_price) from public.ticket_categories c
                              where c.event_id = e.id and not c.is_invitation))
             order by e.starts_at, e.title, e.id)
        from (select * from public.events e
               where e.organization_id = v_org.id and private.is_listed(e)
               order by e.starts_at, e.title, e.id
               limit 50) e), '[]'::jsonb));
end;
$$;

-- -----------------------------------------------------------------------------
-- Notification des abonnés à la première mise au catalogue d'un événement
-- -----------------------------------------------------------------------------
alter table public.events add column followers_notified_at timestamptz;
-- Les événements déjà au catalogue ne déclenchent rien.
update public.events e set followers_notified_at = now()
 where e.is_public and e.status in ('published', 'in_progress');

create function private.notify_followers()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org text;
  r record;
begin
  if new.followers_notified_at is null and private.is_listed(new) then
    new.followers_notified_at := now();
    select o.name into v_org from public.organizations o where o.id = new.organization_id;
    for r in
      select f.user_id from public.organization_followers f
       where f.organization_id = new.organization_id
         and not exists (select 1 from public.organization_members m
                          where m.organization_id = new.organization_id
                            and m.user_id = f.user_id and m.active)
    loop
      perform private.notify_user(
        r.user_id,
        left('Nouvel événement : ' || new.title, 120),
        left('New event: ' || new.title, 120),
        v_org || ' vient de publier un événement. Touchez pour voir la fiche.',
        v_org || ' just published an event. Tap to see it.',
        '/evenement/' || new.id);
    end loop;
  end if;
  return new;
end;
$$;
revoke all on function private.notify_followers() from public, anon, authenticated;

create trigger events_notify_followers
  before update on public.events
  for each row execute function private.notify_followers();
