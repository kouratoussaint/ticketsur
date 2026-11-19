-- =============================================================================
-- Tikéo — Migration 2100 : événements publics par défaut, tickets par type
-- =============================================================================
-- Décisions de Toussaint (19/11/2026, ADR 0015) :
-- * un nouvel événement est « Visible par le public » par défaut (il
--   n'apparaît dans l'Explorer qu'une fois publié) ; l'organisateur peut le
--   rendre privé. Les événements existants gardent leur réglage ;
-- * dans l'onglet Tickets, les tickets se regroupent par type (catégorie) :
--   `event_tickets` accepte `p_category_id`.
-- =============================================================================

alter table public.events alter column is_public set default true;

drop function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean);

create function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_undelivered boolean default false,
  p_category_id uuid default null
)
returns table (
  id uuid,
  public_reference text,
  category_id uuid,
  category_name text,
  status public.ticket_status,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  holder_name text,
  holder_phone text,
  holder_email text,
  last_delivery_channel public.delivery_channel,
  last_delivery_at timestamptz,
  category_is_invitation boolean,
  total_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_search text := nullif(upper(trim(coalesce(p_search, ''))), '');
  -- Recherche de téléphone : au moins 4 chiffres saisis.
  v_digits text := nullif(regexp_replace(coalesce(p_search, ''), '[^0-9]', '', 'g'), '');
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
    select t.id, t.public_reference, t.category_id, c.name, t.status, t.issued_at,
           t.redeemed_at, cp.name, t.revoked_at,
           t.holder_name, t.holder_phone, t.holder_email,
           d.channel, d.sent_at, c.is_invitation,
           count(*) over ()
    from public.tickets t
    join public.ticket_categories c on c.id = t.category_id
    left join public.checkpoints cp on cp.id = t.redeemed_checkpoint_id
    left join lateral (
      select td.channel, td.sent_at
      from public.ticket_deliveries td
      where td.ticket_id = t.id
      order by td.sent_at desc, td.id desc
      limit 1
    ) d on true
    where t.event_id = p_event_id
      and (p_status is null or t.status = p_status)
      and (not coalesce(p_undelivered, false) or d.sent_at is null)
      and (p_category_id is null or t.category_id = p_category_id)
      and (v_search is null
           or t.public_reference like '%' || v_search || '%'
           or upper(c.name) like '%' || v_search || '%'
           or upper(t.holder_name) like '%' || v_search || '%'
           or upper(t.holder_email) like '%' || v_search || '%'
           or (char_length(v_digits) >= 4 and t.holder_phone like '%' || v_digits || '%'))
    order by t.issued_at desc, t.public_reference
    limit least(greatest(coalesce(p_limit, 50), 1), 200)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean, uuid)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean, uuid)
  to authenticated;
