-- ADR 0056 : recettes probables et pertes probables évitées dans le tableau
-- de bord d'un événement (demande de Toussaint, 27/11). Calculées avec le
-- prix indicatif de chaque catégorie (facultatif) ; les invitations ne
-- comptent pas (gratuites).
-- - Recettes probables : tickets entrés (au moins une entrée) × prix.
-- - Pertes probables évitées : tickets de l'événement refusés à la porte
--   (déjà utilisé, annulé, expiré) × prix, un ticket compté une fois. Un
--   « déjà utilisé » moins d'une minute après son entrée est un double
--   passage du contrôleur, pas une fraude : écarté.
-- - QR inconnus ou d'un autre événement : comptés à part, sans montant.

create function private.event_money(p_event_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with cats as (
    select c.id, c.name, c.indicative_price as price, c.is_invitation, c.created_at
      from public.ticket_categories c where c.event_id = p_event_id
  ), admitted as (
    select t.category_id, count(*) as n
      from public.tickets t
     where t.event_id = p_event_id and t.status <> 'revoked' and t.entries_used > 0
     group by t.category_id
  ), refused as (
    select t.category_id, count(distinct t.id) as n
      from public.scan_attempts sa
      join public.tickets t on t.id = sa.ticket_id and t.event_id = p_event_id
     where sa.event_id = p_event_id
       and sa.outcome in ('already_used', 'revoked', 'expired')
       and not (sa.outcome = 'already_used' and t.last_entry_at is not null
                and sa.server_time >= t.last_entry_at
                and sa.server_time < t.last_entry_at + interval '1 minute')
     group by t.category_id
  ), rows as (
    select c.id, c.name, c.price, c.is_invitation, c.created_at,
           coalesce(a.n, 0) as admitted, coalesce(r.n, 0) as refused
      from cats c
      left join admitted a on a.category_id = c.id
      left join refused r on r.category_id = c.id
  )
  select jsonb_build_object(
    'currency', 'XOF',
    'revenue', coalesce(sum(r.admitted * r.price) filter (where not r.is_invitation), 0),
    'revenue_tickets', coalesce(sum(r.admitted) filter (where not r.is_invitation and r.price is not null), 0),
    'revenue_unpriced', coalesce(sum(r.admitted) filter (where not r.is_invitation and r.price is null), 0),
    'avoided', coalesce(sum(r.refused * r.price) filter (where not r.is_invitation), 0),
    'avoided_tickets', coalesce(sum(r.refused) filter (where not r.is_invitation and r.price is not null), 0),
    'avoided_unpriced', coalesce(sum(r.refused) filter (where not r.is_invitation and r.price is null), 0),
    'unknown_refusals', (select count(*) from public.scan_attempts sa
                          where sa.event_id = p_event_id
                            and sa.outcome in ('not_found', 'wrong_event')),
    'categories', coalesce(jsonb_agg(jsonb_build_object(
        'id', r.id, 'name', r.name, 'price', r.price, 'invitation', r.is_invitation,
        'admitted', r.admitted, 'refused', r.refused,
        'revenue', case when r.is_invitation then 0 else r.admitted * r.price end,
        'avoided', case when r.is_invitation then 0 else r.refused * r.price end)
      order by r.created_at, r.name) filter (where r.id is not null), '[]'::jsonb))
  from rows r
$$;
revoke all on function private.event_money(uuid) from public, anon, authenticated;

create or replace function public.event_dashboard(p_event_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_result jsonb := private.event_dashboard_core(p_event_id);
begin
  -- Droits vérifiés par le corps ; le pack ensuite.
  perform private.billing_require_event(p_event_id, 'live_dashboard');
  return v_result || jsonb_build_object('money', private.event_money(p_event_id));
end;
$$;

create or replace function public.closed_event_dashboard(p_event_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform private.open_closed_event_read(p_event_id);
  v_result := private.event_dashboard_core(p_event_id)
              || jsonb_build_object('money', private.event_money(p_event_id));
  perform private.close_closed_read();
  return v_result;
end;
$$;
