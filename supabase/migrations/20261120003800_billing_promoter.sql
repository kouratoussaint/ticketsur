-- Packs et facturation, PR 3b (ADR 0027) : côté promoteur.
--   * notifications : pack activé ou refusé, rappel avant la fin d'un
--     abonnement, facture à l'usage émise, facture en retard ;
--   * jours d'essai d'un pack forfait (une fois par compte) ;
--   * erreurs de limite lisibles par l'app : HINT en JSON (limite, système,
--     événement à l'usage), pour proposer « Dépasser la limite » ;
--   * my_billing v2 : détail des factures, essai déjà utilisé.
-- Aucune donnée personnelle dans les notifications ni le journal.

-- -----------------------------------------------------------------------------
-- Essai
-- -----------------------------------------------------------------------------
alter table public.billing_subscriptions drop constraint billing_subscriptions_duration_check;
alter table public.billing_subscriptions add constraint billing_subscriptions_duration_check
  check (duration in ('month', 'quarter', 'semester', 'year', 'event', 'unlimited', 'trial'));

-- Facture en retard : notification envoyée une seule fois.
alter table public.billing_invoices add column overdue_notified_at timestamptz;

create function public.start_billing_trial(p_pack_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
  v_pack public.billing_packs;
  v_sub public.billing_subscriptions;
begin
  -- Un essai à la fois, par compte (verrou consultatif du compte).
  perform pg_advisory_xact_lock(hashtext('billing:' || v_account::text));
  select p.* into v_pack from public.billing_packs p
   where p.id = p_pack_id and p.system = 'flat' and p.status = 'published'
     and p.code is null and p.trial_days > 0;
  if not found then
    raise exception 'billing_pack_invalid'
      using errcode = '22023', detail = 'Ce pack ne propose pas d''essai.';
  end if;
  if exists (select 1 from public.billing_subscriptions s
              where s.account_id = v_account and s.duration = 'trial') then
    raise exception 'billing_trial_used'
      using errcode = '55000', detail = 'Votre essai gratuit a déjà été utilisé.';
  end if;
  v_sub := private.billing_subscription(v_account);
  if v_sub.id is not null and (v_sub.snapshot->>'code') is null then
    raise exception 'billing_trial_unavailable'
      using errcode = '55000', detail = 'Essai impossible pendant un abonnement payant.';
  end if;
  insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, starts_at,
                                            ends_at, created_by, note)
  values (v_account, v_pack.id, 'trial', private.billing_pack_snapshot(v_pack.id), now(),
          now() + make_interval(days => v_pack.trial_days), v_account, 'Essai')
  returning * into v_sub;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, v_account, 'billing.trial_started', 'billing_subscription', v_sub.id,
          jsonb_build_object('days', v_pack.trial_days));
  return jsonb_build_object('subscription_id', v_sub.id, 'ends_at', v_sub.ends_at);
end;
$$;
revoke all on function public.start_billing_trial(uuid) from public, anon;
grant execute on function public.start_billing_trial(uuid) to authenticated;

create or replace function public.request_billing_addons(p_addons jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
  v_sub public.billing_subscriptions := private.billing_subscription(v_account);
  v_months numeric;
  v_amount integer;
  v_request public.billing_requests;
begin
  if v_sub.id is null or v_sub.duration in ('unlimited', 'trial') then
    raise exception 'billing_subscription_missing'
      using errcode = '55000', detail = 'Aucun abonnement payant en cours.';
  end if;
  v_months := case when v_sub.duration = 'event' then 1
                   else greatest(extract(epoch from (v_sub.ends_at - now())) / 86400 / 30, 0) end;
  v_amount := private.billing_addons_cost(v_sub.snapshot, coalesce(p_addons, '{}'::jsonb), v_months);
  update public.billing_requests r set status = 'cancelled', decided_at = now()
   where r.account_id = v_account and r.status = 'pending';
  insert into public.billing_requests (account_id, kind, subscription_id, addons, amount, reference)
  values (v_account, 'addons', v_sub.id, p_addons, v_amount, private.billing_reference())
  returning * into v_request;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, v_account, 'billing.request_created', 'billing_request', v_request.id,
          jsonb_build_object('addons', true, 'amount', v_amount));
  return jsonb_build_object('id', v_request.id, 'reference', v_request.reference,
                            'amount', v_amount, 'payment', private.billing_payment_info());
end;
$$;
revoke all on function public.request_billing_addons(jsonb) from public, anon;
grant execute on function public.request_billing_addons(jsonb) to authenticated;

create or replace function public.admin_activate_request(
  p_request_id uuid,
  p_channel text,
  p_operator_reference text default null,
  p_paid_at timestamptz default null,
  p_note text default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_request public.billing_requests;
  v_start timestamptz;
  v_sub uuid;
  v_key text;
  v_units integer;
begin
  perform private.require_platform_admin();
  select r.* into v_request from public.billing_requests r where r.id = p_request_id for update;
  if not found or v_request.status <> 'pending' then
    raise exception 'billing_request_not_found'
      using errcode = '55000', detail = 'Demande introuvable ou déjà traitée.';
  end if;
  perform private.billing_record_payment(v_request.account_id, v_request.amount, p_channel,
                                         p_operator_reference, p_paid_at, p_note, v_request.id, null);
  if v_request.kind = 'subscription' then
    select greatest(now(), coalesce(max(s.ends_at), now())) into v_start
      from public.billing_subscriptions s
     where s.account_id = v_request.account_id and s.status = 'active'
       and s.duration not in ('unlimited', 'event', 'trial') and s.ends_at > now()
       and (s.snapshot->>'code') is null;
    insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, addons,
                                              starts_at, ends_at, created_by)
    values (v_request.account_id, v_request.pack_id, v_request.duration,
            private.billing_pack_snapshot(v_request.pack_id), v_request.addons,
            v_start, private.billing_end(v_start, v_request.duration), auth.uid())
    returning id into v_sub;
    -- Un pack payé remplace l'essai en cours.
    update public.billing_subscriptions s
       set status = 'cancelled', cancelled_at = now()
     where s.account_id = v_request.account_id and s.status = 'active' and s.duration = 'trial';
  else
    v_sub := v_request.subscription_id;
    for v_key, v_units in select a.key, a.value::integer from jsonb_each_text(v_request.addons) a loop
      update public.billing_subscriptions s
         set addons = s.addons || jsonb_build_object(v_key, coalesce((s.addons->>v_key)::integer, 0) + v_units)
       where s.id = v_sub;
    end loop;
  end if;
  update public.billing_requests r
     set status = 'activated', decided_at = now(), decided_by = auth.uid(),
         subscription_id = coalesce(r.subscription_id, case when r.kind = 'addons' then v_sub end)
   where r.id = p_request_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_request_activated', 'billing_request', p_request_id,
          jsonb_build_object('addons', v_request.kind = 'addons', 'amount', v_request.amount, 'channel', p_channel));
  return v_sub;
end;
$$;
revoke all on function public.admin_activate_request(uuid, text, text, timestamptz, text) from public, anon;
grant execute on function public.admin_activate_request(uuid, text, text, timestamptz, text) to authenticated;

create or replace function public.my_billing()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
  v_plan jsonb := private.billing_account_plan(v_account);
begin
  return jsonb_build_object(
    'version', 2,
    'plan', v_plan,
    'limits', (select jsonb_object_agg(k, private.billing_limit(v_plan, k))
                 from unnest(private.billing_numeric_options()) k),
    'features', (select jsonb_object_agg(k, private.billing_enabled(v_plan, k))
                   from unnest(private.billing_feature_options()) k),
    'usage', jsonb_build_object(
      'structures', (select count(*) from public.organizations o
                      where o.owner_id = v_account and o.status = 'active'),
      'active_events', (select count(*) from public.events e
                          join public.organizations o on o.id = e.organization_id
                         where o.owner_id = v_account
                           and e.status in ('published', 'in_progress')
                           and coalesce(e.billing_system, case e.billing_mode when 'inherit'
                                        then o.billing_default else e.billing_mode end) = 'flat'),
      'tickets_period', (select count(*) from public.tickets t
                           join public.events e on e.id = t.event_id
                           join public.organizations o on o.id = e.organization_id
                          where o.owner_id = v_account
                            and coalesce(e.billing_system, 'flat') = 'flat'
                            and t.issued_at >= (v_plan->>'period_start')::timestamptz
                            and (v_plan->>'period_end' is null
                                 or t.issued_at < (v_plan->>'period_end')::timestamptz)),
      'members_max', coalesce((select max(n) from (
                       select count(*) as n from public.organization_members m
                         join public.organizations o on o.id = m.organization_id
                        where o.owner_id = v_account and m.active and m.role <> 'owner'
                        group by m.organization_id) x), 0)),
    'organizations', coalesce((
      select jsonb_agg(jsonb_build_object('id', o.id, 'name', o.name,
                                          'billing_default', o.billing_default,
                                          'usage_pack_id', o.billing_usage_pack_id)
                       order by o.name)
        from public.organizations o where o.owner_id = v_account and o.status = 'active'), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(jsonb_build_object('id', r.id, 'kind', r.kind, 'pack_id', r.pack_id,
                                          'duration', r.duration, 'addons', r.addons,
                                          'amount', r.amount, 'reference', r.reference,
                                          'declared_channel', r.declared_channel,
                                          'status', r.status, 'created_at', r.created_at)
                       order by r.created_at desc)
        from (select * from public.billing_requests r0 where r0.account_id = v_account
               order by r0.created_at desc limit 20) r), '[]'::jsonb),
    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object('id', i.id, 'event_id', i.event_id, 'event_title', e.title,
                                          'entries', i.entries, 'free_entries', i.free_entries,
                                          'billable_entries', i.billable_entries,
                                          'entries_amount', i.entries_amount,
                                          'addons_amount', i.addons_amount,
                                          'pack_name', p.name, 'amount', i.amount,
                                          'lines', i.lines, 'status', i.status,
                                          'overdue', i.status = 'due' and i.due_at < now(),
                                          'issued_at', i.issued_at, 'due_at', i.due_at,
                                          'paid_at', i.paid_at)
                       order by i.issued_at desc)
        from (select * from public.billing_invoices i0 where i0.account_id = v_account
               order by i0.issued_at desc limit 50) i
        join public.events e on e.id = i.event_id
        left join public.billing_packs p on p.id = i.pack_id), '[]'::jsonb),
    'trial_used', exists (select 1 from public.billing_subscriptions s
                           where s.account_id = v_account and s.duration = 'trial'),
    'payment', private.billing_payment_info());
end;
$$;
revoke all on function public.my_billing() from public, anon;
grant execute on function public.my_billing() to authenticated;

-- -----------------------------------------------------------------------------
-- Erreurs de limite : HINT en JSON pour l'application
-- -----------------------------------------------------------------------------
create or replace function private.billing_event_plan(p_event uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_owner uuid;
  v_system text;
  v_pack uuid;
begin
  select e.* into v_event from public.events e where e.id = p_event;
  select o.owner_id into v_owner from public.organizations o where o.id = v_event.organization_id;
  select c.system, c.usage_pack_id into v_system, v_pack from private.billing_event_choice(p_event) c;
  if v_system = 'usage' then
    return jsonb_build_object(
      'system', 'usage', 'subscription_id', null, 'event_id', p_event,
      'snapshot', coalesce(v_event.billing_snapshot, private.billing_pack_snapshot(v_pack)),
      'addons', v_event.billing_addons, 'grace', false);
  end if;
  return private.billing_account_plan(v_owner, p_event);
end;
$$;
revoke all on function private.billing_event_plan(uuid) from public, anon, authenticated;

create or replace function private.billing_block_hint(p_plan jsonb, p_limit integer)
returns text
language sql
immutable
set search_path = ''
as $$
  select jsonb_strip_nulls(jsonb_build_object(
    'limit', p_limit,
    'system', p_plan->>'system',
    'event', p_plan->>'event_id'))::text
$$;

create or replace function private.billing_check_limit(p_plan jsonb, p_key text, p_used bigint)
returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_limit integer := private.billing_limit(p_plan, p_key);
begin
  if v_limit is not null and p_used > v_limit then
    raise exception 'billing_limit_%', p_key
      using errcode = '54000',
            detail = format('Votre pack permet %s %s.', v_limit, private.billing_label(p_key)),
            hint = private.billing_block_hint(p_plan, v_limit);
  end if;
end;
$$;

create or replace function private.billing_require(p_plan jsonb, p_key text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if not private.billing_enabled(p_plan, p_key) then
    raise exception 'billing_option_%', p_key
      using errcode = '54000', detail = 'Cette fonction n''est pas comprise dans votre pack.',
            hint = private.billing_block_hint(p_plan, null);
  end if;
end;
$$;

-- -----------------------------------------------------------------------------
-- Notifications
-- -----------------------------------------------------------------------------
-- Montant en FCFA, séparateur de milliers selon la langue.
create function private.billing_money(p_amount integer, p_locale text)
returns text
language sql
immutable
set search_path = ''
as $$
  select replace(to_char(p_amount, 'FM999,999,999,990'), ',',
                 case p_locale when 'en' then ',' else ' ' end) || ' FCFA'
$$;

create function private.billing_push(p_account uuid, p_title_fr text, p_title_en text,
                                     p_body_fr text, p_body_en text, p_route text)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.push_outbox (user_id, title, body, route)
  select p.id,
         case p.locale when 'en' then p_title_en else p_title_fr end,
         case p.locale when 'en' then p_body_en else p_body_fr end,
         p_route
    from public.profiles p
   where p.id = p_account and p.deleted_at is null
$$;
revoke all on function private.billing_push(uuid, text, text, text, text, text) from public, anon, authenticated;

-- Demande activée ou refusée par Tikéo.
create function private.billing_request_notify()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pack text;
begin
  if new.status = old.status then
    return new;
  end if;
  select p.name into v_pack from public.billing_packs p where p.id = new.pack_id;
  if new.status = 'activated' then
    if new.kind = 'addons' then
      perform private.billing_push(new.account_id, 'Suppléments activés', 'Add-ons activated',
        'Vos suppléments sont actifs.', 'Your add-ons are active.', '/facturation');
    else
      perform private.billing_push(new.account_id, 'Pack activé', 'Pack activated',
        format('Votre pack %s est actif.', v_pack), format('Your %s pack is active.', v_pack),
        '/facturation');
    end if;
  elsif new.status = 'refused' then
    perform private.billing_push(new.account_id, 'Demande refusée', 'Request refused',
      format('Votre demande %s n''a pas été validée.', new.reference),
      format('Your request %s was not confirmed.', new.reference),
      '/facturation/demande/' || new.id);
  end if;
  return new;
end;
$$;
create trigger billing_requests_notify
  after update of status on public.billing_requests
  for each row execute function private.billing_request_notify();

-- Facture à l'usage émise (montant dû).
create function private.billing_invoice_notify()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text;
begin
  if new.status <> 'due' then
    return new;
  end if;
  select e.title into v_title from public.events e where e.id = new.event_id;
  perform private.billing_push(new.account_id, 'Facture à payer', 'Invoice to pay',
    format('%s : %s, avant le %s.', v_title, private.billing_money(new.amount, 'fr'),
           to_char(new.due_at, 'DD/MM/YYYY')),
    format('%s: %s, due by %s.', v_title, private.billing_money(new.amount, 'en'),
           to_char(new.due_at, 'YYYY-MM-DD')),
    '/facturation/factures/' || new.id);
  return new;
end;
$$;
create trigger billing_invoices_notify
  after insert on public.billing_invoices
  for each row execute function private.billing_invoice_notify();

-- Rappel avant la fin d'un abonnement (une fois) et factures en retard
-- (une fois). Appelée par push_tick.
create function private.billing_notify(p_now timestamptz default now())
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_days integer := (select s.reminder_days from public.billing_settings s);
  v_sub record;
  v_invoice record;
  v_count integer := 0;
begin
  for v_sub in
    select s.id, s.account_id, s.ends_at, s.duration, s.snapshot->>'name' as pack
      from public.billing_subscriptions s
     where s.status = 'active' and s.reminded_at is null
       and s.duration not in ('unlimited', 'event')
       and s.ends_at > p_now and s.ends_at <= p_now + make_interval(days => v_days)
       -- Déjà renouvelé : rien à rappeler.
       and not exists (select 1 from public.billing_subscriptions n
                        where n.account_id = s.account_id and n.status = 'active'
                          and n.id <> s.id and n.duration <> 'trial'
                          and n.starts_at >= s.ends_at - interval '1 minute')
     order by s.ends_at
     limit 200
     for update of s skip locked
  loop
    perform private.billing_push(v_sub.account_id,
      case v_sub.duration when 'trial' then 'Fin de l''essai' else 'Fin de votre pack' end,
      case v_sub.duration when 'trial' then 'Trial ending' else 'Pack ending' end,
      format('%s se termine le %s. Renouvelez pour garder vos limites.', v_sub.pack,
             to_char(v_sub.ends_at, 'DD/MM/YYYY')),
      format('%s ends on %s. Renew to keep your limits.', v_sub.pack,
             to_char(v_sub.ends_at, 'YYYY-MM-DD')),
      '/facturation');
    update public.billing_subscriptions s set reminded_at = p_now where s.id = v_sub.id;
    v_count := v_count + 1;
  end loop;
  for v_invoice in
    select i.id, i.account_id, i.amount, e.title
      from public.billing_invoices i
      join public.events e on e.id = i.event_id
     where i.status = 'due' and i.due_at < p_now and i.overdue_notified_at is null
     order by i.due_at
     limit 200
     for update of i skip locked
  loop
    perform private.billing_push(v_invoice.account_id, 'Facture en retard', 'Invoice overdue',
      format('%s : %s. Réglez-la pour créer un nouvel événement à l''usage.', v_invoice.title,
             private.billing_money(v_invoice.amount, 'fr')),
      format('%s: %s. Pay it to create a new pay-per-use event.', v_invoice.title,
             private.billing_money(v_invoice.amount, 'en')),
      '/facturation/factures/' || v_invoice.id);
    update public.billing_invoices i set overdue_notified_at = p_now where i.id = v_invoice.id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke all on function private.billing_notify(timestamptz) from public, anon, authenticated;

create or replace function private.push_tick()
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_url text;
  v_key text;
begin
  perform private.enqueue_event_reminders(now());
  -- Factures à l'usage dues (une erreur ici ne bloque pas les notifications).
  begin
    perform private.billing_tick(now());
  exception when others then
    raise warning 'billing_tick: %', sqlerrm;
  end;
  begin
    perform private.billing_notify(now());
  exception when others then
    raise warning 'billing_notify: %', sqlerrm;
  end;
  select s.value into v_url from private.app_settings s where s.key = 'push_dispatch_url';
  select s.value into v_key from private.app_settings s where s.key = 'publishable_key';
  if v_url is null or v_key is null
     or not exists (select 1 from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
                     where n.nspname = 'net' and pr.proname = 'http_post')
     or not exists (select 1 from public.push_outbox o where o.sent_at is null and o.attempts < 5)
  then
    return;
  end if;
  -- Appel asynchrone (pg_net) : la fonction vide la file.
  execute 'select net.http_post(url := $1, body := $2, headers := $3, timeout_milliseconds := 30000)'
    using v_url, '{}'::jsonb,
          jsonb_build_object('content-type', 'application/json',
                             'apikey', v_key, 'authorization', 'Bearer ' || v_key);
end;
$$;
revoke all on function private.push_tick() from public, anon, authenticated;
