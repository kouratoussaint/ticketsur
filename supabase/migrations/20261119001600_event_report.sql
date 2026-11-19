-- =============================================================================
-- TicketSûr — Migration 1600 : liste complète pour le rapport d'événement
-- (lot 2)
-- =============================================================================
-- Le bilan chiffré vient de event_dashboard (migration 1300). La liste des
-- tickets (export CSV) vient d'ici, en un seul appel :
-- * propriétaires et gestionnaires seulement (event_not_found sinon) ;
-- * titulaires compris (données personnelles) : chaque export est journalisé
--   (« event.report_exported », nombre de lignes, jamais leur contenu) ;
-- * aucun jeton QR ;
-- * 50 000 lignes au plus.
-- =============================================================================

create or replace function public.event_report_rows(p_event_id uuid)
returns table (
  public_reference text,
  category_name text,
  status public.ticket_status,
  holder_name text,
  holder_phone text,
  holder_email text,
  issued_at timestamptz,
  redeemed_at timestamptz,
  redeemed_checkpoint_name text,
  revoked_at timestamptz,
  last_delivery_channel public.delivery_channel,
  last_delivery_at timestamptz
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_count integer;
begin
  select e.organization_id into v_org
  from public.events e
  where e.id = p_event_id
    and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if v_org is null then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;

  select count(*) into v_count from public.tickets t where t.event_id = p_event_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_org, auth.uid(), 'event.report_exported', 'event', p_event_id,
          jsonb_build_object('rows', least(v_count, 50000)));

  return query
    select t.public_reference, c.name, t.status,
           t.holder_name, t.holder_phone, t.holder_email,
           t.issued_at, t.redeemed_at, cp.name, t.revoked_at,
           d.channel, d.sent_at
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
    order by c.created_at, c.name, t.holder_name nulls last, t.public_reference
    limit 50000;
end;
$$;
revoke all on function public.event_report_rows(uuid) from public, anon;
grant execute on function public.event_report_rows(uuid) to authenticated;
