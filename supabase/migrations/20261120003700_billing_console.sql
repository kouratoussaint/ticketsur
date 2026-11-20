-- =============================================================================
-- Tikéo — Packs et facturation : console (PR 2, ADR 0027)
-- =============================================================================
-- Écrans C1 à C6 de la spécification `claude/specification-packs-facturation.md`.
-- * `admin_billing()` (version 2) : e-mails des comptes, pack et code des
--   abonnements, nombre d'événements à l'usage par pack, historique des
--   demandes traitées et des factures payées (onglet « Traitées »).
-- * Abonnements (C5) : prolonger, changer de pack, régler les suppléments,
--   motif obligatoire.
-- * Facturation d'un événement déjà figé (section 4) : recherche des
--   événements figés et changement par l'administrateur, motif obligatoire,
--   refusé si une facture a déjà été émise.
-- Aucune donnée personnelle dans le journal : identifiants et compteurs.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Vue d'ensemble de la console (version 2, mêmes clés qu'en version 1 plus
-- des champs ajoutés).
-- -----------------------------------------------------------------------------
create or replace function public.admin_billing()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return jsonb_build_object(
    'version', 2,
    'settings', (select to_jsonb(s) - 'id' from public.billing_settings s),
    'packs', coalesce((
      select jsonb_agg(private.billing_pack_snapshot(p.id)
                       || jsonb_build_object('status', p.status, 'description', p.description,
                                             'sort_order', p.sort_order, 'featured', p.featured,
                                             'trial_days', p.trial_days,
                                             'subscriptions', (select count(*) from public.billing_subscriptions s
                                                                where s.pack_id = p.id and s.status = 'active'),
                                             'events', (select count(*) from public.events e
                                                         where e.billing_snapshot->>'pack_id' = p.id::text))
                       order by p.status, p.system, p.sort_order, p.name)
        from public.billing_packs p), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', r.id, 'account_id', r.account_id, 'account_name', pr.display_name,
               'account_email', u.email,
               'kind', r.kind, 'pack_id', r.pack_id, 'pack_name', p.name, 'duration', r.duration,
               'subscription_id', r.subscription_id,
               'addons', r.addons, 'amount', r.amount, 'reference', r.reference,
               'declared_channel', r.declared_channel,
               'declared_transaction', r.declared_transaction, 'created_at', r.created_at)
             order by r.created_at)
        from public.billing_requests r
        join public.profiles pr on pr.id = r.account_id
        left join auth.users u on u.id = r.account_id
        left join public.billing_packs p on p.id = coalesce(r.pack_id,
                    (select s.pack_id from public.billing_subscriptions s where s.id = r.subscription_id))
       where r.status = 'pending'), '[]'::jsonb),
    'subscriptions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'account_id', s.account_id, 'account_name', pr.display_name,
               'account_email', u.email,
               'pack_id', s.pack_id, 'pack_code', s.snapshot->>'code',
               'pack_name', s.snapshot->>'name', 'duration', s.duration, 'addons', s.addons,
               'starts_at', s.starts_at, 'ends_at', s.ends_at, 'note', s.note)
             order by s.ends_at nulls last)
        from public.billing_subscriptions s
        join public.profiles pr on pr.id = s.account_id
        left join auth.users u on u.id = s.account_id
       where s.status = 'active' and (s.ends_at is null or s.ends_at > now() - interval '30 days')),
      '[]'::jsonb),
    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'account_id', i.account_id, 'account_name', pr.display_name,
               'account_email', u.email,
               'event_id', i.event_id, 'event_title', e.title, 'entries', i.entries,
               'free_entries', i.free_entries, 'entries_amount', i.entries_amount,
               'addons_amount', i.addons_amount,
               'amount', i.amount, 'lines', i.lines, 'issued_at', i.issued_at, 'due_at', i.due_at,
               'overdue', i.due_at < now())
             order by i.due_at)
        from public.billing_invoices i
        join public.profiles pr on pr.id = i.account_id
        left join auth.users u on u.id = i.account_id
        join public.events e on e.id = i.event_id
       where i.status = 'due'), '[]'::jsonb),
    -- Onglet « Traitées » : 50 dernières demandes décidées et factures payées.
    'history', coalesce((
      select jsonb_agg(x.item order by x.at desc)
        from (
          (select jsonb_build_object(
                    'type', 'request', 'id', r.id, 'account_name', pr.display_name,
                    'kind', r.kind, 'pack_name', p.name, 'duration', r.duration,
                    'amount', r.amount, 'reference', r.reference, 'status', r.status,
                    'decided_at', coalesce(r.decided_at, r.created_at),
                    'channel', pay.channel, 'operator_reference', pay.operator_reference,
                    'note', r.note) as item,
                  coalesce(r.decided_at, r.created_at) as at
             from public.billing_requests r
             join public.profiles pr on pr.id = r.account_id
             left join public.billing_packs p on p.id = coalesce(r.pack_id,
                         (select s.pack_id from public.billing_subscriptions s where s.id = r.subscription_id))
             left join public.billing_payments pay on pay.request_id = r.id
            where r.status <> 'pending'
            order by coalesce(r.decided_at, r.created_at) desc
            limit 50)
          union all
          (select jsonb_build_object(
                    'type', 'invoice', 'id', i.id, 'account_name', pr.display_name,
                    'event_title', e.title, 'amount', i.amount, 'status', i.status,
                    'decided_at', i.paid_at, 'channel', pay.channel,
                    'operator_reference', pay.operator_reference, 'note', pay.note),
                  i.paid_at
             from public.billing_invoices i
             join public.profiles pr on pr.id = i.account_id
             join public.events e on e.id = i.event_id
             left join public.billing_payments pay on pay.invoice_id = i.id
            where i.status = 'paid' and i.amount > 0
            order by i.paid_at desc
            limit 50)
        ) x), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_billing() from public, anon;
grant execute on function public.admin_billing() to authenticated;

-- Motif obligatoire des gestes de la console.
create function private.billing_require_note(p_note text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_note is null or char_length(trim(p_note)) < 3 then
    raise exception 'billing_note_required' using errcode = '22023', detail = 'Indiquez le motif.';
  end if;
  return left(trim(p_note), 300);
end;
$$;
revoke all on function private.billing_require_note(text) from public, anon, authenticated;

-- Abonnement actif, verrouillé pour modification.
create function private.billing_active_subscription(p_subscription_id uuid)
returns public.billing_subscriptions
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_sub public.billing_subscriptions;
begin
  select s.* into v_sub from public.billing_subscriptions s
   where s.id = p_subscription_id and s.status = 'active' for update;
  if not found then
    raise exception 'billing_subscription_missing'
      using errcode = '55000', detail = 'Abonnement introuvable ou déjà annulé.';
  end if;
  return v_sub;
end;
$$;
revoke all on function private.billing_active_subscription(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Abonnements (C5)
-- -----------------------------------------------------------------------------
-- Prolonger (ou raccourcir) : nouvelle date de fin, après le début.
create function public.admin_extend_subscription(
  p_subscription_id uuid,
  p_ends_at timestamptz,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_sub public.billing_subscriptions;
  v_note text;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  if p_ends_at is null or p_ends_at <= v_sub.starts_at then
    raise exception 'billing_subscription_invalid'
      using errcode = '22023', detail = 'La fin doit suivre le début de l''abonnement.';
  end if;
  update public.billing_subscriptions s
     set ends_at = p_ends_at, reminded_at = null, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_extended', 'billing_subscription',
          p_subscription_id, jsonb_build_object('later', p_ends_at > coalesce(v_sub.ends_at, p_ends_at)));
end;
$$;
revoke all on function public.admin_extend_subscription(uuid, timestamptz, text) from public, anon;
grant execute on function public.admin_extend_subscription(uuid, timestamptz, text) to authenticated;

-- Changer de pack (forfait) : mêmes dates ; les suppléments doivent exister
-- dans le nouveau pack.
create function public.admin_change_subscription_pack(
  p_subscription_id uuid,
  p_pack_id uuid,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_sub public.billing_subscriptions;
  v_snapshot jsonb;
  v_note text;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  select private.billing_pack_snapshot(p.id) into v_snapshot
    from public.billing_packs p where p.id = p_pack_id and p.system = 'flat';
  if v_snapshot is null then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Choisissez un pack forfait.';
  end if;
  perform private.billing_addons_cost(v_snapshot, v_sub.addons, 1);
  update public.billing_subscriptions s
     set pack_id = p_pack_id, snapshot = v_snapshot, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_pack_changed', 'billing_subscription',
          p_subscription_id, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_change_subscription_pack(uuid, uuid, text) from public, anon;
grant execute on function public.admin_change_subscription_pack(uuid, uuid, text) to authenticated;

-- Régler les suppléments d'un abonnement (geste commercial, correction).
create function public.admin_set_subscription_addons(
  p_subscription_id uuid,
  p_addons jsonb,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_sub public.billing_subscriptions;
  v_note text;
  v_addons jsonb;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  v_sub := private.billing_active_subscription(p_subscription_id);
  -- Zéro tranche : le supplément disparaît.
  select coalesce(jsonb_object_agg(a.key, a.value), '{}'::jsonb) into v_addons
    from jsonb_each(coalesce(p_addons, '{}'::jsonb)) a
   where jsonb_typeof(a.value) <> 'number' or (a.value::text)::numeric <> 0;
  perform private.billing_addons_cost(v_sub.snapshot, v_addons, 1);
  update public.billing_subscriptions s
     set addons = v_addons, note = v_note
   where s.id = p_subscription_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_addons_set', 'billing_subscription',
          p_subscription_id, jsonb_build_object('options', (select count(*) from jsonb_object_keys(v_addons))));
end;
$$;
revoke all on function public.admin_set_subscription_addons(uuid, jsonb, text) from public, anon;
grant execute on function public.admin_set_subscription_addons(uuid, jsonb, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Facturation d'un événement (section 4 : changement par l'administrateur)
-- -----------------------------------------------------------------------------
-- Événements dont la facturation est réglée (figée au premier ticket, ou
-- choisie), recherchés par titre ou structure.
create function public.admin_billing_events(p_search text default null, p_limit integer default 20)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_query text := nullif(private.fold(trim(coalesce(p_search, ''))), '');
begin
  perform private.require_platform_admin();
  return coalesce((
    select jsonb_agg(x.item order by x.starts_at desc)
      from (
        select jsonb_build_object(
                 'id', e.id, 'title', e.title, 'organization_name', o.name,
                 'owner_name', pr.display_name, 'starts_at', e.starts_at, 'ends_at', e.ends_at,
                 'status', e.status, 'mode', e.billing_mode,
                 'system', c.system, 'locked', e.billing_locked_at is not null,
                 'pack_name', coalesce(e.billing_snapshot->>'name', up.name),
                 'invoice_status', i.status) as item,
               e.starts_at
          from public.events e
          join public.organizations o on o.id = e.organization_id
          join public.profiles pr on pr.id = o.owner_id
          cross join lateral private.billing_event_choice(e.id) c
          left join public.billing_packs up on up.id = c.usage_pack_id
          left join public.billing_invoices i on i.event_id = e.id
         where v_query is null
            or private.fold(e.title) like '%' || v_query || '%'
            or private.fold(o.name) like '%' || v_query || '%'
         order by e.starts_at desc
         limit least(greatest(coalesce(p_limit, 20), 1), 50)
      ) x), '[]'::jsonb);
end;
$$;
revoke all on function public.admin_billing_events(text, integer) from public, anon;
grant execute on function public.admin_billing_events(text, integer) to authenticated;

-- Changer la facturation d'un événement, même figée. Refusé si une facture
-- à l'usage a déjà été émise (la régler ou l'annuler d'abord).
create function public.admin_set_event_billing(
  p_event_id uuid,
  p_system text,
  p_usage_pack_id uuid,
  p_note text
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_note text;
begin
  perform private.require_platform_admin();
  v_note := private.billing_require_note(p_note);
  select e.* into v_event from public.events e where e.id = p_event_id for update;
  if not found then
    raise exception 'event_not_found' using errcode = 'P0002', detail = 'Événement introuvable.';
  end if;
  if p_system not in ('flat', 'usage')
     or (p_system = 'usage' and not exists (select 1 from public.billing_packs p
                                             where p.id = p_usage_pack_id and p.system = 'usage')) then
    raise exception 'billing_choice_invalid'
      using errcode = '22023', detail = 'Forfait, ou à l''usage avec un pack à l''usage.';
  end if;
  if exists (select 1 from public.billing_invoices i
              where i.event_id = p_event_id and i.status <> 'cancelled') then
    raise exception 'billing_invoice_exists'
      using errcode = '55000', detail = 'Une facture a déjà été émise pour cet événement.';
  end if;
  update public.events e
     set billing_mode = p_system,
         billing_usage_pack_id = case when p_system = 'usage' then p_usage_pack_id end,
         -- Figé : la copie suit le nouveau choix ; suppléments remis à zéro.
         billing_system = case when e.billing_locked_at is not null then p_system end,
         billing_snapshot = case when e.billing_locked_at is not null and p_system = 'usage'
                                 then private.billing_pack_snapshot(p_usage_pack_id) end,
         billing_addons = '{}'::jsonb
   where e.id = p_event_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'admin.billing_event_set', 'event', p_event_id,
          jsonb_build_object('system', p_system));
end;
$$;
revoke all on function public.admin_set_event_billing(uuid, text, uuid, text) from public, anon;
grant execute on function public.admin_set_event_billing(uuid, text, uuid, text) to authenticated;
