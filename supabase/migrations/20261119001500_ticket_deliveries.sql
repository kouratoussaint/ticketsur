-- =============================================================================
-- TicketSûr — Migration 1500 : journal des envois de tickets (lot 2)
-- =============================================================================
-- Envoi assisté : l'organisateur envoie le ticket depuis son téléphone
-- (WhatsApp, SMS, e-mail). L'application ne sait pas si le message est
-- vraiment parti : elle n'enregistre un envoi que lorsque l'organisateur le
-- confirme. Le journal sert à toute l'équipe (« qui a déjà reçu son
-- ticket ? ») et à reprendre une série interrompue.
--
-- * ticket_deliveries : append-only, sans donnée personnelle (ni numéro, ni
--   adresse, ni contenu du message) ; lisible des seuls organisateurs.
-- * record_ticket_delivery : ticket valable (issued) seulement.
-- * event_tickets : dernier envoi (canal, heure) et filtre « jamais envoyés ».
--
-- Erreurs : 42501 ticket_not_found | 22023 delivery_channel_invalid
--           55000 ticket_not_sendable
-- =============================================================================

create type public.delivery_channel as enum ('whatsapp', 'sms', 'email');

create table public.ticket_deliveries (
  -- Croissant : départage deux envois de la même transaction (même heure).
  id bigint generated always as identity primary key,
  ticket_id uuid not null references public.tickets (id) on delete cascade,
  channel public.delivery_channel not null,
  sent_by uuid not null references public.profiles (id),
  sent_at timestamptz not null default now()
);
create index ticket_deliveries_ticket_idx on public.ticket_deliveries (ticket_id, sent_at desc, id desc);

alter table public.ticket_deliveries enable row level security;

create policy ticket_deliveries_managers on public.ticket_deliveries for select to authenticated
using (
  exists (
    select 1 from public.tickets t
    join public.events e on e.id = t.event_id
    where t.id = ticket_deliveries.ticket_id
      and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
  )
);
-- Lecture seule pour l'API : l'écriture passe par record_ticket_delivery.
revoke all on public.ticket_deliveries from anon, authenticated;
grant select on public.ticket_deliveries to authenticated;

-- -----------------------------------------------------------------------------
-- Enregistrer un envoi confirmé
-- -----------------------------------------------------------------------------
create or replace function public.record_ticket_delivery(p_ticket_id uuid, p_channel text)
returns timestamptz
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_ticket public.tickets%rowtype;
  v_org uuid;
  v_channel public.delivery_channel;
  v_at timestamptz := now();
begin
  if p_channel is null or p_channel not in ('whatsapp', 'sms', 'email') then
    raise exception 'delivery_channel_invalid'
      using errcode = '22023', detail = 'Canal inconnu (whatsapp, sms ou email).';
  end if;
  v_channel := p_channel::public.delivery_channel;

  select t.* into v_ticket from public.tickets t where t.id = p_ticket_id;
  select e.organization_id into v_org from public.events e where e.id = v_ticket.event_id;
  if v_ticket.id is null or auth.uid() is null
     or not private.has_org_role(v_org, array['owner','manager']::public.member_role[]) then
    raise exception 'ticket_not_found'
      using errcode = '42501', detail = 'Ticket introuvable ou droits insuffisants.';
  end if;
  if v_ticket.status <> 'issued' then
    raise exception 'ticket_not_sendable'
      using errcode = '55000', detail = 'Seul un ticket valable, pas encore utilisé, peut être envoyé.';
  end if;

  insert into public.ticket_deliveries (ticket_id, channel, sent_by, sent_at)
  values (p_ticket_id, v_channel, auth.uid(), v_at);
  return v_at;
end;
$$;
revoke all on function public.record_ticket_delivery(uuid, text) from public, anon;
grant execute on function public.record_ticket_delivery(uuid, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Liste : dernier envoi et filtre « jamais envoyés » (type de retour modifié)
-- -----------------------------------------------------------------------------
drop function public.event_tickets(uuid, public.ticket_status, text, integer, integer);

create function public.event_tickets(
  p_event_id uuid,
  p_status public.ticket_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0,
  p_undelivered boolean default false
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
           d.channel, d.sent_at,
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
revoke all on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean)
  from public, anon;
grant execute on function public.event_tickets(uuid, public.ticket_status, text, integer, integer, boolean)
  to authenticated;
