-- =============================================================================
-- Tikéo — Packs, quotas et facturation : base (PR 1, ADR 0027)
-- =============================================================================
-- Spécification validée : doc du projet `claude/specification-packs-facturation.md`.
-- * Packs (forfait ou usage), options chiffrées ou oui / non, suppléments.
-- * Abonnements forfait portés par le COMPTE du promoteur ; pack gratuit
--   « Découverte » sans abonnement ; pack « Lancement » offert 3 mois aux
--   comptes existants.
-- * Facturation par structure (défaut) et par événement, figée au premier
--   ticket émis ; à l'usage, options et prix copiés dans l'événement.
-- * Quotas et options vérifiés côté serveur (déclencheurs sur les écritures,
--   et au début des lectures concernées) ; jamais à la porte.
-- * Factures à l'usage : entrées réelles (chaque entrée d'un pass, invitations
--   comprises), entrées offertes, paliers, suppléments ; émises à la clôture du
--   contrôle ou N heures après la fin ; estimation en direct.
-- * Demandes d'activation, paiements reçus (Orange Money, Moov) et réglages,
--   validés par un administrateur. Aucun numéro ni nom de payeur stocké.
-- Erreurs : MESSAGE `billing_limit_<option>`, `billing_option_<option>`,
-- `billing_overdue`, `billing_usage_pack_missing`, `billing_locked`… (DETAIL
-- lisible).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Réglages
-- -----------------------------------------------------------------------------
create table public.billing_settings (
  id boolean primary key default true check (id),
  orange_money_number text check (orange_money_number is null or char_length(orange_money_number) <= 30),
  moov_money_number text check (moov_money_number is null or char_length(moov_money_number) <= 30),
  beneficiary text check (beneficiary is null or char_length(beneficiary) <= 80),
  instructions text check (instructions is null or char_length(instructions) <= 500),
  usage_payment_days integer not null default 7 check (usage_payment_days between 1 and 90),
  invoice_delay_hours integer not null default 24 check (invoice_delay_hours between 0 and 720),
  reminder_days integer not null default 7 check (reminder_days between 0 and 60),
  grace_days integer not null default 7 check (grace_days between 0 and 60),
  updated_at timestamptz not null default now()
);
insert into public.billing_settings default values;
alter table public.billing_settings enable row level security;
revoke all on public.billing_settings from anon, authenticated;

-- -----------------------------------------------------------------------------
-- Packs et options
-- -----------------------------------------------------------------------------
create table public.billing_packs (
  id uuid primary key default gen_random_uuid(),
  -- Packs du système : « decouverte » (gratuit), « lancement » (offert).
  code text unique check (code is null or code in ('decouverte', 'lancement')),
  name text not null check (char_length(name) between 2 and 60),
  description text check (description is null or char_length(description) <= 300),
  system text not null check (system in ('flat', 'usage')),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  sort_order integer not null default 0,
  featured boolean not null default false,
  -- Forfait : prix mensuel et prix de chaque durée proposée
  -- ({"month": 9000, "quarter": 24000, "semester": …, "year": …, "event": …,
  --   "unlimited": 0 pour les packs du système}).
  monthly_price integer check (monthly_price is null or monthly_price >= 0),
  durations jsonb not null default '{}'::jsonb,
  trial_days integer not null default 0 check (trial_days between 0 and 90),
  -- Usage : prix par entrée, entrées offertes, paliers
  -- ([{"up_to": 500, "price": 150}, {"up_to": null, "price": 100}]).
  entry_price integer check (entry_price is null or entry_price >= 0),
  free_entries integer not null default 0 check (free_entries >= 0),
  tiers jsonb not null default '[]'::jsonb,
  payment_days integer check (payment_days is null or payment_days between 1 and 90),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (jsonb_typeof(durations) = 'object' and jsonb_typeof(tiers) = 'array'),
  check (system = 'usage' or entry_price is null),
  check (system = 'flat' or durations = '{}'::jsonb)
);
alter table public.billing_packs enable row level security;
revoke all on public.billing_packs from anon, authenticated;

-- Liste fixe des options (ajouter une option = une migration).
create function private.billing_numeric_options()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array['structures', 'active_events', 'tickets_per_event', 'tickets_per_period',
               'members_per_structure', 'controllers_per_event']
$$;

create function private.billing_feature_options()
returns text[]
language sql
immutable
set search_path = ''
as $$
  select array['assisted_send', 'bulk_send', 'import', 'export', 'print_sheet',
               'custom_design', 'named_tickets', 'live_dashboard', 'public_catalog',
               'priority_support']
$$;

create table public.billing_pack_options (
  pack_id uuid not null references public.billing_packs (id) on delete cascade,
  option_key text not null,
  -- Option chiffrée : valeur incluse (null = illimité).
  included integer check (included is null or included >= 0),
  -- Option oui / non : incluse, en supplément, indisponible.
  state text check (state is null or state in ('included', 'addon', 'unavailable')),
  -- Supplément : prix par tranche (par mois en forfait, par événement à
  -- l'usage), taille de la tranche, plafond en tranches. Prix null = pas de
  -- supplément possible.
  addon_price integer check (addon_price is null or addon_price >= 0),
  addon_step integer not null default 1 check (addon_step >= 1),
  addon_cap integer check (addon_cap is null or addon_cap >= 1),
  primary key (pack_id, option_key),
  check (option_key = any (private.billing_numeric_options() || private.billing_feature_options())),
  check ((option_key = any (private.billing_numeric_options())) = (state is null)),
  check (state is distinct from 'addon' or addon_price is not null)
);
alter table public.billing_pack_options enable row level security;
revoke all on public.billing_pack_options from anon, authenticated;

-- -----------------------------------------------------------------------------
-- Abonnements, demandes, paiements, factures
-- -----------------------------------------------------------------------------
create table public.billing_subscriptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles (id),
  pack_id uuid not null references public.billing_packs (id),
  duration text not null check (duration in ('month', 'quarter', 'semester', 'year', 'event', 'unlimited')),
  -- Pack copié à l'activation : une modification du pack ne change pas un
  -- abonnement en cours.
  snapshot jsonb not null,
  addons jsonb not null default '{}'::jsonb check (jsonb_typeof(addons) = 'object'),
  status text not null default 'active' check (status in ('active', 'cancelled')),
  starts_at timestamptz not null,
  ends_at timestamptz,
  -- Durée « un seul événement » : l'événement couvert (au premier ticket).
  bound_event_id uuid references public.events (id),
  reminded_at timestamptz,
  created_by uuid references public.profiles (id),
  -- Motif d'un abonnement offert ou annulé par l'administrateur.
  note text check (note is null or char_length(note) <= 300),
  created_at timestamptz not null default now(),
  cancelled_at timestamptz,
  check (ends_at is null or ends_at > starts_at)
);
create index billing_subscriptions_account_idx on public.billing_subscriptions (account_id, starts_at desc);
alter table public.billing_subscriptions enable row level security;
revoke all on public.billing_subscriptions from anon, authenticated;

create table public.billing_requests (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles (id),
  kind text not null check (kind in ('subscription', 'addons')),
  pack_id uuid references public.billing_packs (id),
  duration text check (duration is null or duration in ('month', 'quarter', 'semester', 'year', 'event')),
  subscription_id uuid references public.billing_subscriptions (id),
  addons jsonb not null default '{}'::jsonb check (jsonb_typeof(addons) = 'object'),
  amount integer not null check (amount >= 0),
  reference text not null unique check (reference ~ '^TK-[A-Z0-9]{4}$'),
  declared_channel text check (declared_channel is null or declared_channel in ('orange_money', 'moov_money')),
  declared_transaction text check (declared_transaction is null or char_length(declared_transaction) between 3 and 60),
  status text not null default 'pending' check (status in ('pending', 'activated', 'refused', 'cancelled')),
  created_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references public.profiles (id),
  note text check (note is null or char_length(note) <= 300),
  check ((kind = 'subscription') = (pack_id is not null and duration is not null)),
  check ((kind = 'addons') = (subscription_id is not null))
);
create index billing_requests_account_idx on public.billing_requests (account_id, created_at desc);
create index billing_requests_pending_idx on public.billing_requests (created_at) where status = 'pending';
alter table public.billing_requests enable row level security;
revoke all on public.billing_requests from anon, authenticated;

create table public.billing_invoices (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles (id),
  event_id uuid not null unique references public.events (id),
  pack_id uuid references public.billing_packs (id),
  entries integer not null check (entries >= 0),
  free_entries integer not null default 0,
  billable_entries integer not null default 0,
  entries_amount integer not null default 0,
  addons_amount integer not null default 0,
  amount integer not null check (amount >= 0),
  lines jsonb not null default '[]'::jsonb,
  status text not null default 'due' check (status in ('due', 'paid', 'cancelled')),
  issued_at timestamptz not null default now(),
  due_at timestamptz not null,
  paid_at timestamptz
);
create index billing_invoices_account_idx on public.billing_invoices (account_id, issued_at desc);
alter table public.billing_invoices enable row level security;
revoke all on public.billing_invoices from anon, authenticated;

create table public.billing_payments (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles (id),
  amount integer not null check (amount >= 0),
  channel text not null check (channel in ('orange_money', 'moov_money', 'other')),
  operator_reference text check (operator_reference is null or char_length(operator_reference) between 3 and 60),
  paid_at timestamptz not null,
  note text check (note is null or char_length(note) <= 300),
  request_id uuid unique references public.billing_requests (id),
  invoice_id uuid unique references public.billing_invoices (id),
  recorded_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  check ((request_id is null) <> (invoice_id is null))
);
alter table public.billing_payments enable row level security;
revoke all on public.billing_payments from anon, authenticated;

-- Choix de facturation : structure (défaut) et événement (figé au premier
-- ticket émis).
alter table public.organizations
  add column billing_default text not null default 'flat' check (billing_default in ('flat', 'usage')),
  add column billing_usage_pack_id uuid references public.billing_packs (id);
alter table public.events
  add column billing_mode text not null default 'inherit' check (billing_mode in ('inherit', 'flat', 'usage')),
  add column billing_usage_pack_id uuid references public.billing_packs (id),
  add column billing_system text check (billing_system is null or billing_system in ('flat', 'usage')),
  add column billing_locked_at timestamptz,
  add column billing_snapshot jsonb,
  add column billing_addons jsonb not null default '{}'::jsonb check (jsonb_typeof(billing_addons) = 'object');

-- -----------------------------------------------------------------------------
-- Calcul des droits
-- -----------------------------------------------------------------------------
-- Copie d'un pack : options (par clé), prix et durées.
create function private.billing_pack_snapshot(p_pack_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'pack_id', p.id, 'code', p.code, 'name', p.name, 'system', p.system,
    'monthly_price', p.monthly_price, 'durations', p.durations,
    'entry_price', p.entry_price, 'free_entries', p.free_entries, 'tiers', p.tiers,
    'payment_days', p.payment_days,
    'options', coalesce((
      select jsonb_object_agg(o.option_key, jsonb_build_object(
               'included', o.included, 'state', o.state, 'addon_price', o.addon_price,
               'addon_step', o.addon_step, 'addon_cap', o.addon_cap))
        from public.billing_pack_options o where o.pack_id = p.id), '{}'::jsonb))
  from public.billing_packs p
  where p.id = p_pack_id
$$;
revoke all on function private.billing_pack_snapshot(uuid) from public, anon, authenticated;

-- Abonnement en vigueur d'un compte (période de grâce comprise), pour un
-- événement donné (un abonnement « un seul événement » ne couvre que le sien).
create function private.billing_subscription(p_account uuid, p_event uuid default null)
returns public.billing_subscriptions
language sql
stable
security definer
set search_path = ''
as $$
  select s.*
    from public.billing_subscriptions s
   where s.account_id = p_account
     and s.status = 'active'
     and s.starts_at <= now()
     and (s.ends_at is null
          or now() < s.ends_at + make_interval(days => (select bs.grace_days from public.billing_settings bs)))
     and (s.bound_event_id is null or s.bound_event_id is not distinct from p_event)
   order by s.starts_at desc
   limit 1
$$;
revoke all on function private.billing_subscription(uuid, uuid) from public, anon, authenticated;

-- Droits forfait d'un compte : abonnement en vigueur, sinon pack gratuit.
create function private.billing_account_plan(p_account uuid, p_event uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_sub public.billing_subscriptions;
begin
  v_sub := private.billing_subscription(p_account, p_event);
  if v_sub.id is not null then
    return jsonb_build_object(
      'system', 'flat', 'subscription_id', v_sub.id, 'duration', v_sub.duration,
      'snapshot', v_sub.snapshot, 'addons', v_sub.addons,
      'period_start', v_sub.starts_at,
      'period_end', v_sub.ends_at,
      'grace', v_sub.ends_at is not null and now() >= v_sub.ends_at);
  end if;
  -- Pack gratuit : quotas par mois civil.
  return jsonb_build_object(
    'system', 'flat', 'subscription_id', null, 'duration', 'unlimited',
    'snapshot', private.billing_pack_snapshot(
      (select p.id from public.billing_packs p where p.code = 'decouverte')),
    'addons', '{}'::jsonb,
    'period_start', date_trunc('month', now()),
    'period_end', date_trunc('month', now()) + interval '1 month',
    'grace', false);
end;
$$;
revoke all on function private.billing_account_plan(uuid, uuid) from public, anon, authenticated;

-- Système et pack usage d'un événement, choix de la structure compris.
create function private.billing_event_choice(p_event uuid)
returns table (system text, usage_pack_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(e.billing_system,
                  case e.billing_mode when 'inherit' then o.billing_default else e.billing_mode end),
         coalesce(e.billing_usage_pack_id, o.billing_usage_pack_id)
    from public.events e
    join public.organizations o on o.id = e.organization_id
   where e.id = p_event
$$;
revoke all on function private.billing_event_choice(uuid) from public, anon, authenticated;

-- Droits d'un événement : copie figée (usage), pack usage choisi, ou forfait
-- du compte.
create function private.billing_event_plan(p_event uuid)
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
      'system', 'usage', 'subscription_id', null,
      'snapshot', coalesce(v_event.billing_snapshot, private.billing_pack_snapshot(v_pack)),
      'addons', v_event.billing_addons, 'grace', false);
  end if;
  return private.billing_account_plan(v_owner, p_event);
end;
$$;
revoke all on function private.billing_event_plan(uuid) from public, anon, authenticated;

-- Droits d'une structure (membres) : pack usage choisi par défaut, sinon
-- forfait du propriétaire.
create function private.billing_org_plan(p_org uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org public.organizations;
begin
  select o.* into v_org from public.organizations o where o.id = p_org;
  if v_org.billing_default = 'usage' and v_org.billing_usage_pack_id is not null then
    return jsonb_build_object(
      'system', 'usage', 'subscription_id', null,
      'snapshot', private.billing_pack_snapshot(v_org.billing_usage_pack_id),
      'addons', '{}'::jsonb, 'grace', false);
  end if;
  return private.billing_account_plan(v_org.owner_id);
end;
$$;
revoke all on function private.billing_org_plan(uuid) from public, anon, authenticated;

-- Limite d'une option chiffrée (null = illimité). Option absente du pack :
-- illimitée (aucune fonctionnalité retirée par oubli).
create function private.billing_limit(p_plan jsonb, p_key text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case
    when p_plan->'snapshot'->'options'->p_key is null then null
    when p_plan->'snapshot'->'options'->p_key->>'included' is null then null
    else (p_plan->'snapshot'->'options'->p_key->>'included')::integer
         + coalesce((p_plan->'addons'->>p_key)::integer, 0)
           * coalesce((p_plan->'snapshot'->'options'->p_key->>'addon_step')::integer, 1)
  end
$$;

-- Fonction oui / non comprise (incluse, ou supplément pris). Option absente
-- du pack : comprise.
create function private.billing_enabled(p_plan jsonb, p_key text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select case coalesce(p_plan->'snapshot'->'options'->p_key->>'state', 'included')
    when 'included' then true
    when 'addon' then coalesce((p_plan->'addons'->>p_key)::integer, 0) >= 1
    else false
  end
$$;

create function private.billing_label(p_key text)
returns text
language sql
immutable
set search_path = ''
as $$
  select case p_key
    when 'structures' then 'structures'
    when 'active_events' then 'événements actifs en même temps'
    when 'tickets_per_event' then 'tickets par événement'
    when 'tickets_per_period' then 'tickets sur la période'
    when 'members_per_structure' then 'membres par structure'
    when 'controllers_per_event' then 'contrôleurs par événement'
    else p_key
  end
$$;

create function private.billing_check_limit(p_plan jsonb, p_key text, p_used bigint)
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
            hint = v_limit::text;
  end if;
end;
$$;

create function private.billing_require(p_plan jsonb, p_key text)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if not private.billing_enabled(p_plan, p_key) then
    raise exception 'billing_option_%', p_key
      using errcode = '54000', detail = 'Cette fonction n''est pas comprise dans votre pack.';
  end if;
end;
$$;

-- Vérification d'une fonction pour un événement (lectures concernées).
create function private.billing_require_event(p_event uuid, p_key text)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.billing_require(private.billing_event_plan(p_event), p_key);
end;
$$;
revoke all on function private.billing_require_event(uuid, text) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Montant à l'usage (facture et estimation)
-- -----------------------------------------------------------------------------
create function private.billing_usage_amount(p_snapshot jsonb, p_addons jsonb, p_entries integer)
returns jsonb
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_free integer := coalesce((p_snapshot->>'free_entries')::integer, 0);
  v_billable integer := greatest(coalesce(p_entries, 0) - v_free, 0);
  v_price integer := coalesce((p_snapshot->>'entry_price')::integer, 0);
  v_lines jsonb := '[]'::jsonb;
  v_entries_amount integer := 0;
  v_addons_amount integer := 0;
  v_from integer := 0;
  v_tier jsonb;
  v_upto integer;
  v_count integer;
  v_key text;
  v_units integer;
  v_unit_price integer;
begin
  if jsonb_array_length(coalesce(p_snapshot->'tiers', '[]'::jsonb)) = 0 then
    v_entries_amount := v_billable * v_price;
    if v_billable > 0 then
      v_lines := v_lines || jsonb_build_object('kind', 'entries', 'count', v_billable,
                                               'price', v_price, 'amount', v_entries_amount);
    end if;
  else
    -- Paliers marginaux, du plus bas au plus haut (« jusqu'à » vide = au-delà).
    for v_tier in
      select t from jsonb_array_elements(p_snapshot->'tiers') t
       order by (t->>'up_to')::integer nulls last
    loop
      exit when v_from >= v_billable;
      v_upto := (v_tier->>'up_to')::integer;
      v_count := least(coalesce(v_upto, v_billable), v_billable) - v_from;
      continue when v_count <= 0;
      v_entries_amount := v_entries_amount + v_count * (v_tier->>'price')::integer;
      v_lines := v_lines || jsonb_build_object(
        'kind', 'tier', 'from', v_from + 1, 'to', v_from + v_count, 'count', v_count,
        'price', (v_tier->>'price')::integer, 'amount', v_count * (v_tier->>'price')::integer);
      v_from := v_from + v_count;
    end loop;
  end if;
  for v_key, v_units in
    select a.key, a.value::integer from jsonb_each_text(coalesce(p_addons, '{}'::jsonb)) a
     order by a.key
  loop
    continue when v_units <= 0;
    v_unit_price := coalesce((p_snapshot->'options'->v_key->>'addon_price')::integer, 0);
    v_addons_amount := v_addons_amount + v_units * v_unit_price;
    v_lines := v_lines || jsonb_build_object('kind', 'addon', 'option', v_key, 'units', v_units,
                                             'price', v_unit_price, 'amount', v_units * v_unit_price);
  end loop;
  return jsonb_build_object(
    'entries', coalesce(p_entries, 0), 'free_entries', least(v_free, coalesce(p_entries, 0)),
    'billable_entries', v_billable, 'entries_amount', v_entries_amount,
    'addons_amount', v_addons_amount, 'amount', v_entries_amount + v_addons_amount,
    'lines', v_lines);
end;
$$;

-- Entrées réelles d'un événement : chaque entrée acceptée (chaque entrée
-- d'un pass, invitations comprises).
create function private.billing_entries(p_event uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer from public.scan_attempts sa
   where sa.event_id = p_event and sa.outcome = 'accepted'
$$;
revoke all on function private.billing_entries(uuid) from public, anon, authenticated;

-- Émet la facture à l'usage d'un événement (une seule fois). Montant nul :
-- facture réglée d'office. Renvoie l'identifiant, null si rien à facturer.
create function private.billing_issue_invoice(p_event uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_owner uuid;
  v_calc jsonb;
  v_days integer;
  v_id uuid;
begin
  select e.* into v_event from public.events e where e.id = p_event for update;
  if v_event.id is null or v_event.billing_system is distinct from 'usage' then
    return null;
  end if;
  select i.id into v_id from public.billing_invoices i where i.event_id = p_event;
  if v_id is not null then
    return v_id;
  end if;
  select o.owner_id into v_owner from public.organizations o where o.id = v_event.organization_id;
  v_calc := private.billing_usage_amount(v_event.billing_snapshot, v_event.billing_addons,
                                         private.billing_entries(p_event));
  v_days := coalesce((v_event.billing_snapshot->>'payment_days')::integer,
                     (select bs.usage_payment_days from public.billing_settings bs));
  insert into public.billing_invoices (account_id, event_id, pack_id, entries, free_entries,
                                       billable_entries, entries_amount, addons_amount, amount,
                                       lines, status, due_at, paid_at)
  values (v_owner, p_event, (v_event.billing_snapshot->>'pack_id')::uuid,
          (v_calc->>'entries')::integer, (v_calc->>'free_entries')::integer,
          (v_calc->>'billable_entries')::integer, (v_calc->>'entries_amount')::integer,
          (v_calc->>'addons_amount')::integer, (v_calc->>'amount')::integer, v_calc->'lines',
          case when (v_calc->>'amount')::integer = 0 then 'paid' else 'due' end,
          now() + make_interval(days => v_days),
          case when (v_calc->>'amount')::integer = 0 then now() end)
  returning id into v_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, null, 'billing.invoice_issued', 'event', p_event,
          jsonb_build_object('entries', (v_calc->>'entries')::integer,
                             'amount', (v_calc->>'amount')::integer));
  return v_id;
end;
$$;
revoke all on function private.billing_issue_invoice(uuid) from public, anon, authenticated;

-- Facture à l'usage en retard (bloque un NOUVEL événement à l'usage).
create function private.billing_overdue(p_account uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (select 1 from public.billing_invoices i
                  where i.account_id = p_account and i.status = 'due' and i.due_at < now())
$$;
revoke all on function private.billing_overdue(uuid) from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Vérifications (déclencheurs)
-- -----------------------------------------------------------------------------
-- Ticket émis : figer la facturation de l'événement au premier ticket, puis
-- tickets par événement, tickets de la période (forfait), tickets nominatifs.
create function private.billing_on_ticket()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_owner uuid;
  v_system text;
  v_pack uuid;
  v_plan jsonb;
  v_sub public.billing_subscriptions;
  v_limit integer;
begin
  select e.* into v_event from public.events e where e.id = new.event_id;
  select o.owner_id into v_owner from public.organizations o where o.id = v_event.organization_id;
  -- Un compte à la fois : les quotas de la période ne se dépassent pas en
  -- émettant en parallèle sur deux événements.
  perform pg_advisory_xact_lock(hashtextextended('billing:' || v_owner::text, 0));

  if v_event.billing_locked_at is null then
    select c.system, c.usage_pack_id into v_system, v_pack from private.billing_event_choice(new.event_id) c;
    if v_system = 'usage' then
      if v_pack is null or not exists (select 1 from public.billing_packs p
                                        where p.id = v_pack and p.system = 'usage') then
        raise exception 'billing_usage_pack_missing'
          using errcode = '55000', detail = 'Choisissez un pack à l''usage pour cet événement.';
      end if;
      if private.billing_overdue(v_owner) then
        raise exception 'billing_overdue'
          using errcode = '54000',
                detail = 'Une facture à l''usage est en retard : réglez-la pour émettre des tickets sur un nouvel événement à l''usage.';
      end if;
      update public.events e
         set billing_system = 'usage', billing_locked_at = now(),
             billing_usage_pack_id = v_pack,
             billing_snapshot = private.billing_pack_snapshot(v_pack)
       where e.id = new.event_id;
    else
      update public.events e
         set billing_system = 'flat', billing_locked_at = now()
       where e.id = new.event_id;
      -- Abonnement « un seul événement » : couvre celui-ci, jusqu'à sa fin.
      v_sub := private.billing_subscription(v_owner, new.event_id);
      if v_sub.duration = 'event' and v_sub.bound_event_id is null then
        update public.billing_subscriptions s
           set bound_event_id = new.event_id,
               ends_at = greatest(v_event.ends_at, s.starts_at + interval '1 hour')
         where s.id = v_sub.id;
      end if;
    end if;
  end if;

  v_plan := private.billing_event_plan(new.event_id);
  if private.billing_limit(v_plan, 'tickets_per_event') is not null then
    perform private.billing_check_limit(v_plan, 'tickets_per_event',
      (select count(*) from public.tickets t
        where t.event_id = new.event_id and t.status <> 'revoked'));
  end if;
  v_limit := private.billing_limit(v_plan, 'tickets_per_period');
  if v_limit is not null and v_plan->>'system' = 'flat' then
    perform private.billing_check_limit(v_plan, 'tickets_per_period',
      (select count(*) from public.tickets t
         join public.events e on e.id = t.event_id
         join public.organizations o on o.id = e.organization_id
        where o.owner_id = v_owner
          and coalesce(e.billing_system, 'flat') = 'flat'
          and t.issued_at >= (v_plan->>'period_start')::timestamptz
          and (v_plan->>'period_end' is null or t.issued_at < (v_plan->>'period_end')::timestamptz)));
  end if;
  if new.holder_name is not null or new.holder_phone is not null or new.holder_email is not null then
    perform private.billing_require(v_plan, 'named_tickets');
  end if;
  return null;
end;
$$;
create trigger tickets_billing
  after insert on public.tickets
  for each row execute function private.billing_on_ticket();

-- Événement publié : événements actifs en même temps (publié ou en cours).
-- Catalogue public : un événement ne devient visible que si le pack le permet.
create function private.billing_on_event()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid;
  v_plan jsonb;
begin
  select o.owner_id into v_owner from public.organizations o where o.id = new.organization_id;
  if tg_op = 'INSERT' then
    -- Visible par défaut (ADR 0015) seulement si le pack comprend le catalogue.
    if new.is_public and not private.billing_enabled(
         private.billing_org_plan(new.organization_id), 'public_catalog') then
      new.is_public := false;
    end if;
    return new;
  end if;
  if new.is_public and not old.is_public then
    perform private.billing_require(private.billing_event_plan(new.id), 'public_catalog');
  end if;
  if new.status in ('published', 'in_progress') and old.status not in ('published', 'in_progress') then
    perform pg_advisory_xact_lock(hashtextextended('billing:' || v_owner::text, 0));
    v_plan := private.billing_event_plan(new.id);
    if private.billing_limit(v_plan, 'active_events') is not null then
      perform private.billing_check_limit(v_plan, 'active_events',
        1 + (select count(*) from public.events e
               join public.organizations o on o.id = e.organization_id
              where o.owner_id = v_owner and e.id <> new.id
                and e.status in ('published', 'in_progress')
                and coalesce(e.billing_system,
                             case e.billing_mode when 'inherit' then o.billing_default
                                                 else e.billing_mode end)
                    = v_plan->>'system'));
    end if;
  end if;
  return new;
end;
$$;
create trigger events_billing_insert
  before insert on public.events
  for each row execute function private.billing_on_event();
create trigger events_billing_update
  before update of status, is_public on public.events
  for each row execute function private.billing_on_event();

-- Clôture du contrôle d'un événement à l'usage : facture émise aussitôt.
create function private.billing_on_event_closed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'closed' and old.status <> 'closed' and new.billing_system = 'usage' then
    perform private.billing_issue_invoice(new.id);
  end if;
  return null;
end;
$$;
create trigger events_billing_closed
  after update of status on public.events
  for each row execute function private.billing_on_event_closed();

-- Nouvelle structure : nombre de structures du compte (forfait).
create function private.billing_on_organization()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_advisory_xact_lock(hashtextextended('billing:' || new.owner_id::text, 0));
  perform private.billing_check_limit(private.billing_account_plan(new.owner_id), 'structures',
    1 + (select count(*) from public.organizations o
          where o.owner_id = new.owner_id and o.status = 'active'));
  return new;
end;
$$;
create trigger organizations_billing
  before insert on public.organizations
  for each row execute function private.billing_on_organization();

-- Membre actif : membres de l'équipe par structure (propriétaire non compté).
create function private.billing_on_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.active and new.role <> 'owner' and (tg_op = 'INSERT' or not old.active) then
    perform private.billing_check_limit(private.billing_org_plan(new.organization_id),
      'members_per_structure',
      (select count(*) from public.organization_members m
        where m.organization_id = new.organization_id and m.active and m.role <> 'owner'));
  end if;
  return null;
end;
$$;
create trigger organization_members_billing
  after insert or update of active on public.organization_members
  for each row execute function private.billing_on_member();

-- Contrôleur affecté : contrôleurs par événement (personnes distinctes).
create function private.billing_on_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.active and (tg_op = 'INSERT' or not old.active) then
    perform private.billing_check_limit(private.billing_event_plan(new.event_id),
      'controllers_per_event',
      (select count(distinct a.user_id) from public.event_assignments a
        where a.event_id = new.event_id and a.active));
  end if;
  return null;
end;
$$;
create trigger event_assignments_billing
  after insert or update of active on public.event_assignments
  for each row execute function private.billing_on_assignment();

-- Envoi assisté.
create function private.billing_on_delivery()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.billing_require_event(
    (select t.event_id from public.tickets t where t.id = new.ticket_id), 'assisted_send');
  return new;
end;
$$;
create trigger ticket_deliveries_billing
  before insert on public.ticket_deliveries
  for each row execute function private.billing_on_delivery();

-- Design de ticket importé.
create function private.billing_on_template()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.kind = 'custom' and (tg_op = 'INSERT' or old.kind <> 'custom') then
    perform private.billing_require_event(
      (select c.event_id from public.ticket_categories c where c.id = new.category_id),
      'custom_design');
  end if;
  return new;
end;
$$;
create trigger ticket_category_templates_billing
  before insert or update of kind on public.ticket_category_templates
  for each row execute function private.billing_on_template();

-- -----------------------------------------------------------------------------
-- Outils des demandes
-- -----------------------------------------------------------------------------
create function private.billing_months(p_duration text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case p_duration
    when 'month' then 1 when 'quarter' then 3 when 'semester' then 6 when 'year' then 12
    when 'event' then 1 else 0 end
$$;

create function private.billing_end(p_start timestamptz, p_duration text)
returns timestamptz
language sql
immutable
set search_path = ''
as $$
  select case p_duration
    when 'unlimited' then null
    -- « Un seul événement » : fin fixée par l'événement couvert ; d'ici là,
    -- un an au plus pour l'utiliser.
    when 'event' then p_start + interval '1 year'
    else p_start + make_interval(months => private.billing_months(p_duration)) end
$$;

-- Coût des suppléments demandés pour [p_months] mois (forfait) ou pour un
-- événement (usage, p_months = 1). Vérifie options, tranches et plafonds.
create function private.billing_addons_cost(p_snapshot jsonb, p_addons jsonb, p_months numeric)
returns integer
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_key text;
  v_units integer;
  v_option jsonb;
  v_total numeric := 0;
begin
  if p_addons is null or jsonb_typeof(p_addons) <> 'object' then
    raise exception 'billing_addons_invalid' using errcode = '22023', detail = 'Suppléments invalides.';
  end if;
  for v_key, v_units in select a.key, a.value::integer from jsonb_each_text(p_addons) a loop
    v_option := p_snapshot->'options'->v_key;
    if v_units < 0 or v_option is null or v_option->>'addon_price' is null
       or (v_option->>'state' is not null and v_option->>'state' <> 'addon')
       or (v_option->>'state' = 'addon' and v_units > 1)
       or (v_option->>'addon_cap' is not null and v_units > (v_option->>'addon_cap')::integer) then
      raise exception 'billing_addons_invalid'
        using errcode = '22023', detail = format('Supplément impossible : %s.', v_key);
    end if;
    v_total := v_total + v_units * (v_option->>'addon_price')::integer * p_months;
  end loop;
  return round(v_total)::integer;
end;
$$;

create function private.billing_reference()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  c_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_ref text;
begin
  loop
    v_ref := 'TK-' || (select string_agg(substr(c_alphabet, 1 + (get_byte(b, i) % 32), 1), '' order by i)
                         from (select extensions.gen_random_bytes(4) as b) x,
                              generate_series(0, 3) i);
    exit when not exists (select 1 from public.billing_requests r where r.reference = v_ref);
  end loop;
  return v_ref;
end;
$$;
revoke all on function private.billing_reference() from public, anon, authenticated;

create function private.billing_payment_info()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'orange_money_number', s.orange_money_number, 'moov_money_number', s.moov_money_number,
    'beneficiary', s.beneficiary, 'instructions', s.instructions)
  from public.billing_settings s
$$;
revoke all on function private.billing_payment_info() from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- Promoteur : lecture
-- -----------------------------------------------------------------------------
-- Packs publiés (écrans « Choisir un pack »).
create function public.billing_catalog()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'unauthorized' using errcode = '42501', detail = 'Connexion requise.';
  end if;
  return coalesce((
    select jsonb_agg(private.billing_pack_snapshot(p.id)
                     || jsonb_build_object('description', p.description, 'featured', p.featured,
                                           'trial_days', p.trial_days)
                     order by p.system, p.sort_order, p.name)
      from public.billing_packs p where p.status = 'published'), '[]'::jsonb);
end;
$$;
revoke all on function public.billing_catalog() from public, anon;
grant execute on function public.billing_catalog() to authenticated;

-- Mon pack : droits du compte, consommation, demandes, factures, paiement.
create function public.my_billing()
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
    'version', 1,
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
                                          'entries', i.entries, 'amount', i.amount,
                                          'lines', i.lines, 'status', i.status,
                                          'overdue', i.status = 'due' and i.due_at < now(),
                                          'issued_at', i.issued_at, 'due_at', i.due_at,
                                          'paid_at', i.paid_at)
                       order by i.issued_at desc)
        from (select * from public.billing_invoices i0 where i0.account_id = v_account
               order by i0.issued_at desc limit 50) i
        join public.events e on e.id = i.event_id), '[]'::jsonb),
    'payment', private.billing_payment_info());
end;
$$;
revoke all on function public.my_billing() from public, anon;
grant execute on function public.my_billing() to authenticated;

-- Facturation d'un événement : choix, verrou, estimation en direct, facture.
create function public.event_billing(p_event_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_plan jsonb;
  v_system text;
  v_pack uuid;
begin
  select e.* into v_event from public.events e
   where e.id = p_event_id
     and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[]);
  if not found then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  select c.system, c.usage_pack_id into v_system, v_pack from private.billing_event_choice(p_event_id) c;
  v_plan := private.billing_event_plan(p_event_id);
  return jsonb_build_object(
    'version', 1,
    'mode', v_event.billing_mode,
    'system', v_system,
    'usage_pack_id', v_pack,
    'locked', v_event.billing_locked_at is not null,
    'pack_name', v_plan->'snapshot'->>'name',
    'addons', v_event.billing_addons,
    'limits', (select jsonb_object_agg(k, private.billing_limit(v_plan, k))
                 from unnest(private.billing_numeric_options()) k),
    'features', (select jsonb_object_agg(k, private.billing_enabled(v_plan, k))
                   from unnest(private.billing_feature_options()) k),
    'estimate', case when v_system = 'usage' then
                  private.billing_usage_amount(v_plan->'snapshot', v_event.billing_addons,
                                               private.billing_entries(p_event_id)) end,
    'invoice', (select jsonb_build_object('id', i.id, 'amount', i.amount, 'status', i.status,
                                          'due_at', i.due_at)
                  from public.billing_invoices i where i.event_id = p_event_id));
end;
$$;
revoke all on function public.event_billing(uuid) from public, anon;
grant execute on function public.event_billing(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Promoteur : choix et demandes
-- -----------------------------------------------------------------------------
create function public.set_organization_billing(
  p_organization_id uuid,
  p_default text,
  p_usage_pack_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  if not private.has_org_role(p_organization_id, array['owner']::public.member_role[]) then
    raise exception 'organization_not_found'
      using errcode = '42501', detail = 'Structure introuvable ou droits insuffisants.';
  end if;
  if p_default not in ('flat', 'usage')
     or (p_default = 'usage' and not exists (
           select 1 from public.billing_packs p
            where p.id = p_usage_pack_id and p.system = 'usage' and p.status = 'published')) then
    raise exception 'billing_choice_invalid'
      using errcode = '22023', detail = 'Choisissez « Forfait » ou un pack à l''usage publié.';
  end if;
  update public.organizations o
     set billing_default = p_default,
         billing_usage_pack_id = case when p_default = 'usage' then p_usage_pack_id
                                      else o.billing_usage_pack_id end
   where o.id = p_organization_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (p_organization_id, auth.uid(), 'billing.organization_default_set', 'organization',
          p_organization_id, jsonb_build_object('system', p_default));
  return jsonb_build_object('billing_default', p_default, 'usage_pack_id', p_usage_pack_id);
end;
$$;
revoke all on function public.set_organization_billing(uuid, text, uuid) from public, anon;
grant execute on function public.set_organization_billing(uuid, text, uuid) to authenticated;

create function public.set_event_billing(
  p_event_id uuid,
  p_mode text,
  p_usage_pack_id uuid default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events;
begin
  select e.* into v_event from public.events e
   where e.id = p_event_id
     and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
   for update;
  if not found then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  if v_event.billing_locked_at is not null then
    raise exception 'billing_locked'
      using errcode = '55000', detail = 'Facturation figée dès le premier ticket émis.';
  end if;
  if p_mode not in ('inherit', 'flat', 'usage')
     or (p_mode = 'usage' and p_usage_pack_id is not null and not exists (
           select 1 from public.billing_packs p
            where p.id = p_usage_pack_id and p.system = 'usage' and p.status = 'published')) then
    raise exception 'billing_choice_invalid'
      using errcode = '22023', detail = 'Choix de facturation invalide.';
  end if;
  update public.events e
     set billing_mode = p_mode,
         billing_usage_pack_id = case when p_mode = 'usage' then p_usage_pack_id end
   where e.id = p_event_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'billing.event_mode_set', 'event', p_event_id,
          jsonb_build_object('mode', p_mode));
  return public.event_billing(p_event_id);
end;
$$;
revoke all on function public.set_event_billing(uuid, text, uuid) from public, anon;
grant execute on function public.set_event_billing(uuid, text, uuid) to authenticated;

-- « Dépasser la limite » sur un événement à l'usage : supplément ajouté à
-- la facture de fin d'événement.
create function public.add_event_billing_addon(p_event_id uuid, p_option text, p_units integer)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_plan jsonb;
  v_addons jsonb;
begin
  select e.* into v_event from public.events e
   where e.id = p_event_id
     and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])
   for update;
  if not found then
    raise exception 'event_not_found'
      using errcode = '42501', detail = 'Événement introuvable ou droits insuffisants.';
  end if;
  v_plan := private.billing_event_plan(p_event_id);
  if v_plan->>'system' <> 'usage' or p_units is null or p_units < 1 then
    raise exception 'billing_addons_invalid'
      using errcode = '22023', detail = 'Supplément réservé aux événements à l''usage.';
  end if;
  v_addons := v_event.billing_addons
              || jsonb_build_object(p_option,
                                    coalesce((v_event.billing_addons->>p_option)::integer, 0) + p_units);
  perform private.billing_addons_cost(v_plan->'snapshot', v_addons, 1);
  update public.events e set billing_addons = v_addons where e.id = p_event_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (v_event.organization_id, auth.uid(), 'billing.addon_added', 'event', p_event_id,
          jsonb_build_object('option', p_option, 'units', p_units));
  return public.event_billing(p_event_id);
end;
$$;
revoke all on function public.add_event_billing_addon(uuid, text, integer) from public, anon;
grant execute on function public.add_event_billing_addon(uuid, text, integer) to authenticated;

-- Demande d'activation d'un pack forfait (montant = durée + suppléments).
create function public.request_billing_pack(p_pack_id uuid, p_duration text, p_addons jsonb default '{}'::jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
  v_snapshot jsonb;
  v_price integer;
  v_amount integer;
  v_request public.billing_requests;
begin
  select private.billing_pack_snapshot(p.id) into v_snapshot
    from public.billing_packs p
   where p.id = p_pack_id and p.system = 'flat' and p.status = 'published' and p.code is null;
  v_price := (v_snapshot->'durations'->>p_duration)::integer;
  if v_snapshot is null or v_price is null or p_duration = 'unlimited' then
    raise exception 'billing_pack_invalid'
      using errcode = '22023', detail = 'Pack ou durée indisponible.';
  end if;
  v_amount := v_price + private.billing_addons_cost(v_snapshot, coalesce(p_addons, '{}'::jsonb),
                                                    private.billing_months(p_duration));
  -- Une seule demande en attente à la fois : la précédente est annulée.
  update public.billing_requests r set status = 'cancelled', decided_at = now()
   where r.account_id = v_account and r.status = 'pending';
  insert into public.billing_requests (account_id, kind, pack_id, duration, addons, amount, reference)
  values (v_account, 'subscription', p_pack_id, p_duration, coalesce(p_addons, '{}'::jsonb),
          v_amount, private.billing_reference())
  returning * into v_request;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, v_account, 'billing.request_created', 'billing_request', v_request.id,
          jsonb_build_object('addons', false, 'duration', p_duration, 'amount', v_amount));
  return jsonb_build_object('id', v_request.id, 'reference', v_request.reference,
                            'amount', v_amount, 'payment', private.billing_payment_info());
end;
$$;
revoke all on function public.request_billing_pack(uuid, text, jsonb) from public, anon;
grant execute on function public.request_billing_pack(uuid, text, jsonb) to authenticated;

-- Suppléments en cours d'abonnement : au prorata des jours restants.
create function public.request_billing_addons(p_addons jsonb)
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
  if v_sub.id is null or v_sub.duration = 'unlimited' then
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

-- « J'ai payé » : canal et identifiant reçu par SMS (facultatif).
create function public.declare_billing_payment(p_request_id uuid, p_channel text, p_transaction text default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
begin
  if p_channel not in ('orange_money', 'moov_money')
     or (p_transaction is not null and char_length(trim(p_transaction)) not between 3 and 60) then
    raise exception 'billing_payment_invalid'
      using errcode = '22023', detail = 'Canal ou identifiant de transaction invalide.';
  end if;
  update public.billing_requests r
     set declared_channel = p_channel, declared_transaction = nullif(trim(p_transaction), '')
   where r.id = p_request_id and r.account_id = v_account and r.status = 'pending';
  if not found then
    raise exception 'billing_request_not_found'
      using errcode = '42501', detail = 'Demande introuvable ou déjà traitée.';
  end if;
end;
$$;
revoke all on function public.declare_billing_payment(uuid, text, text) from public, anon;
grant execute on function public.declare_billing_payment(uuid, text, text) to authenticated;

create function public.cancel_billing_request(p_request_id uuid)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_account uuid := private.require_wallet_user();
begin
  update public.billing_requests r set status = 'cancelled', decided_at = now()
   where r.id = p_request_id and r.account_id = v_account and r.status = 'pending';
  if not found then
    raise exception 'billing_request_not_found'
      using errcode = '42501', detail = 'Demande introuvable ou déjà traitée.';
  end if;
end;
$$;
revoke all on function public.cancel_billing_request(uuid) from public, anon;
grant execute on function public.cancel_billing_request(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Lectures soumises au pack : rapports (export) et tableau de bord en direct
-- -----------------------------------------------------------------------------
-- Les corps existants passent dans `private` ; la fonction publique vérifie
-- les droits, puis le pack, puis appelle le corps (contrat inchangé).
alter function public.event_report_rows(uuid) set schema private;
alter function private.event_report_rows(uuid) rename to event_report_rows_core;
revoke all on function private.event_report_rows_core(uuid) from public, anon, authenticated;

create function public.event_report_rows(p_event_id uuid)
returns table (
  public_reference text,
  category_name text,
  category_is_invitation boolean,
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
begin
  if exists (select 1 from public.events e
              where e.id = p_event_id
                and private.has_org_role(e.organization_id, array['owner','manager']::public.member_role[])) then
    perform private.billing_require_event(p_event_id, 'export');
  end if;
  return query select * from private.event_report_rows_core(p_event_id);
end;
$$;
revoke all on function public.event_report_rows(uuid) from public, anon;
grant execute on function public.event_report_rows(uuid) to authenticated;

alter function public.event_dashboard(uuid) set schema private;
alter function private.event_dashboard(uuid) rename to event_dashboard_core;
revoke all on function private.event_dashboard_core(uuid) from public, anon, authenticated;

create function public.event_dashboard(p_event_id uuid)
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
  return v_result;
end;
$$;
revoke all on function public.event_dashboard(uuid) from public, anon;
grant execute on function public.event_dashboard(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Tâche planifiée : factures à l'usage N heures après la fin
-- -----------------------------------------------------------------------------
create function private.billing_tick(p_now timestamptz default now())
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_delay integer := (select s.invoice_delay_hours from public.billing_settings s);
  v_event uuid;
  v_count integer := 0;
begin
  for v_event in
    select e.id from public.events e
     where e.billing_system = 'usage'
       and e.status not in ('draft')
       and e.ends_at + make_interval(hours => v_delay) <= p_now
       and not exists (select 1 from public.billing_invoices i where i.event_id = e.id)
     order by e.ends_at
     limit 200
  loop
    perform private.billing_issue_invoice(v_event);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke all on function private.billing_tick(timestamptz) from public, anon, authenticated;

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

-- -----------------------------------------------------------------------------
-- Console (administrateur de la plateforme)
-- -----------------------------------------------------------------------------
create function public.admin_billing()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  return jsonb_build_object(
    'version', 1,
    'settings', (select to_jsonb(s) - 'id' from public.billing_settings s),
    'packs', coalesce((
      select jsonb_agg(private.billing_pack_snapshot(p.id)
                       || jsonb_build_object('status', p.status, 'description', p.description,
                                             'sort_order', p.sort_order, 'featured', p.featured,
                                             'trial_days', p.trial_days,
                                             'subscriptions', (select count(*) from public.billing_subscriptions s
                                                                where s.pack_id = p.id and s.status = 'active'))
                       order by p.status, p.system, p.sort_order, p.name)
        from public.billing_packs p), '[]'::jsonb),
    'requests', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', r.id, 'account_id', r.account_id, 'account_name', pr.display_name,
               'kind', r.kind, 'pack_id', r.pack_id, 'pack_name', p.name, 'duration', r.duration,
               'addons', r.addons, 'amount', r.amount, 'reference', r.reference,
               'declared_channel', r.declared_channel,
               'declared_transaction', r.declared_transaction, 'created_at', r.created_at)
             order by r.created_at)
        from public.billing_requests r
        join public.profiles pr on pr.id = r.account_id
        left join public.billing_packs p on p.id = coalesce(r.pack_id,
                    (select s.pack_id from public.billing_subscriptions s where s.id = r.subscription_id))
       where r.status = 'pending'), '[]'::jsonb),
    'subscriptions', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', s.id, 'account_id', s.account_id, 'account_name', pr.display_name,
               'pack_name', s.snapshot->>'name', 'duration', s.duration, 'addons', s.addons,
               'starts_at', s.starts_at, 'ends_at', s.ends_at, 'note', s.note)
             order by s.ends_at nulls last)
        from public.billing_subscriptions s
        join public.profiles pr on pr.id = s.account_id
       where s.status = 'active' and (s.ends_at is null or s.ends_at > now() - interval '30 days')),
      '[]'::jsonb),
    'invoices', coalesce((
      select jsonb_agg(jsonb_build_object(
               'id', i.id, 'account_id', i.account_id, 'account_name', pr.display_name,
               'event_id', i.event_id, 'event_title', e.title, 'entries', i.entries,
               'amount', i.amount, 'lines', i.lines, 'issued_at', i.issued_at, 'due_at', i.due_at,
               'overdue', i.due_at < now())
             order by i.due_at)
        from public.billing_invoices i
        join public.profiles pr on pr.id = i.account_id
        join public.events e on e.id = i.event_id
       where i.status = 'due'), '[]'::jsonb));
end;
$$;
revoke all on function public.admin_billing() from public, anon;
grant execute on function public.admin_billing() to authenticated;

-- Créer ou modifier un pack et ses options (remplacées en bloc).
create function public.admin_save_pack(p_pack_id uuid, p_data jsonb)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_pack public.billing_packs;
  v_id uuid;
  v_system text;
  v_option jsonb;
  v_key text;
  v_prev integer := -1;
  v_tier jsonb;
  v_last boolean := false;
begin
  perform private.require_platform_admin();
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Pack invalide.';
  end if;
  if p_pack_id is not null then
    select p.* into v_pack from public.billing_packs p where p.id = p_pack_id for update;
    if not found then
      raise exception 'billing_pack_not_found' using errcode = '22023', detail = 'Pack introuvable.';
    end if;
  end if;
  -- Le système d'un pack ne change pas après sa création.
  v_system := coalesce(v_pack.system, p_data->>'system');
  if v_system is null or v_system not in ('flat', 'usage') then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Système : forfait ou usage.';
  end if;
  -- Paliers : « jusqu'à » croissants, le dernier peut être vide (au-delà).
  for v_tier in select t from jsonb_array_elements(coalesce(p_data->'tiers', '[]'::jsonb)) t loop
    if v_last or jsonb_typeof(v_tier->'price') <> 'number' or (v_tier->>'price')::numeric < 0
       or (v_tier->>'up_to' is not null and (v_tier->>'up_to')::integer <= v_prev) then
      raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Paliers invalides.';
    end if;
    v_last := v_tier->>'up_to' is null;
    v_prev := coalesce((v_tier->>'up_to')::integer, v_prev);
  end loop;
  begin
    if p_pack_id is null then
      insert into public.billing_packs (name, description, system, sort_order, featured,
                                        monthly_price, durations, trial_days, entry_price,
                                        free_entries, tiers, payment_days)
      values (trim(p_data->>'name'), nullif(trim(p_data->>'description'), ''), v_system,
              coalesce((p_data->>'sort_order')::integer, 0),
              coalesce((p_data->>'featured')::boolean, false),
              (p_data->>'monthly_price')::integer, coalesce(p_data->'durations', '{}'::jsonb),
              coalesce((p_data->>'trial_days')::integer, 0), (p_data->>'entry_price')::integer,
              coalesce((p_data->>'free_entries')::integer, 0), coalesce(p_data->'tiers', '[]'::jsonb),
              (p_data->>'payment_days')::integer)
      returning id into v_id;
    else
      update public.billing_packs p
         set name = trim(p_data->>'name'),
             description = nullif(trim(p_data->>'description'), ''),
             sort_order = coalesce((p_data->>'sort_order')::integer, p.sort_order),
             featured = coalesce((p_data->>'featured')::boolean, p.featured),
             monthly_price = (p_data->>'monthly_price')::integer,
             durations = coalesce(p_data->'durations', '{}'::jsonb),
             trial_days = coalesce((p_data->>'trial_days')::integer, 0),
             entry_price = (p_data->>'entry_price')::integer,
             free_entries = coalesce((p_data->>'free_entries')::integer, 0),
             tiers = coalesce(p_data->'tiers', '[]'::jsonb),
             payment_days = (p_data->>'payment_days')::integer,
             updated_at = now()
       where p.id = p_pack_id
      returning id into v_id;
    end if;
    -- Prix des durées : entiers positifs, durées connues.
    if exists (select 1 from jsonb_each(coalesce(p_data->'durations', '{}'::jsonb)) d
                where d.key not in ('month', 'quarter', 'semester', 'year', 'event', 'unlimited')
                   or jsonb_typeof(d.value) <> 'number' or (d.value::text)::numeric < 0) then
      raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Prix des durées invalides.';
    end if;
    if p_data ? 'options' then
      delete from public.billing_pack_options o where o.pack_id = v_id;
      for v_option in select x from jsonb_array_elements(p_data->'options') x loop
        v_key := v_option->>'key';
        insert into public.billing_pack_options (pack_id, option_key, included, state,
                                                 addon_price, addon_step, addon_cap)
        values (v_id, v_key,
                case when v_key = any (private.billing_numeric_options())
                     then (v_option->>'included')::integer end,
                case when v_key = any (private.billing_feature_options())
                     then coalesce(v_option->>'state', 'included') end,
                (v_option->>'addon_price')::integer,
                coalesce((v_option->>'addon_step')::integer, 1),
                (v_option->>'addon_cap')::integer);
      end loop;
    end if;
  exception
    when check_violation or not_null_violation or invalid_text_representation
         or unique_violation or numeric_value_out_of_range then
      raise exception 'billing_pack_invalid'
        using errcode = '22023', detail = 'Pack invalide : vérifiez le nom, les prix et les options.';
  end;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_pack_saved', 'billing_pack', v_id,
          jsonb_build_object('created', p_pack_id is null));
  return v_id;
end;
$$;
revoke all on function public.admin_save_pack(uuid, jsonb) from public, anon;
grant execute on function public.admin_save_pack(uuid, jsonb) to authenticated;

create function public.admin_set_pack_status(p_pack_id uuid, p_status text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_code text;
begin
  perform private.require_platform_admin();
  select p.code into v_code from public.billing_packs p where p.id = p_pack_id for update;
  if not found or p_status not in ('draft', 'published', 'archived') then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Pack ou état invalide.';
  end if;
  -- Le pack gratuit reste publié : c'est le pack des comptes sans abonnement.
  if v_code = 'decouverte' and p_status <> 'published' then
    raise exception 'billing_pack_protected'
      using errcode = '55000', detail = 'Le pack Découverte reste publié.';
  end if;
  update public.billing_packs p set status = p_status, updated_at = now() where p.id = p_pack_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_pack_status_set', 'billing_pack', p_pack_id,
          jsonb_build_object('status', p_status));
end;
$$;
revoke all on function public.admin_set_pack_status(uuid, text) from public, anon;
grant execute on function public.admin_set_pack_status(uuid, text) to authenticated;

create function public.admin_save_billing_settings(p_data jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  begin
    update public.billing_settings s
       set orange_money_number = nullif(trim(p_data->>'orange_money_number'), ''),
           moov_money_number = nullif(trim(p_data->>'moov_money_number'), ''),
           beneficiary = nullif(trim(p_data->>'beneficiary'), ''),
           instructions = nullif(trim(p_data->>'instructions'), ''),
           usage_payment_days = coalesce((p_data->>'usage_payment_days')::integer, s.usage_payment_days),
           invoice_delay_hours = coalesce((p_data->>'invoice_delay_hours')::integer, s.invoice_delay_hours),
           reminder_days = coalesce((p_data->>'reminder_days')::integer, s.reminder_days),
           grace_days = coalesce((p_data->>'grace_days')::integer, s.grace_days),
           updated_at = now();
  exception
    when check_violation or invalid_text_representation or numeric_value_out_of_range then
      raise exception 'billing_settings_invalid' using errcode = '22023', detail = 'Réglages invalides.';
  end;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_settings_saved', 'billing_settings', null, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_save_billing_settings(jsonb) from public, anon;
grant execute on function public.admin_save_billing_settings(jsonb) to authenticated;

-- Paiement reçu (Orange Money, Moov, autre) : enregistrement commun.
create function private.billing_record_payment(
  p_account uuid, p_amount integer, p_channel text, p_operator_reference text,
  p_paid_at timestamptz, p_note text, p_request_id uuid, p_invoice_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  begin
    insert into public.billing_payments (account_id, amount, channel, operator_reference, paid_at,
                                         note, request_id, invoice_id, recorded_by)
    values (p_account, p_amount, p_channel, nullif(trim(p_operator_reference), ''),
            coalesce(p_paid_at, now()), nullif(trim(p_note), ''), p_request_id, p_invoice_id,
            auth.uid())
    returning id into v_id;
  exception when check_violation then
    raise exception 'billing_payment_invalid'
      using errcode = '22023', detail = 'Canal, référence ou note invalide.';
  end;
  return v_id;
end;
$$;
revoke all on function private.billing_record_payment(uuid, integer, text, text, timestamptz, text, uuid, uuid)
  from public, anon, authenticated;

-- Valider une demande : paiement reçu, abonnement (ou suppléments) activé.
-- Un renouvellement commence à la fin de l'abonnement payant en cours.
create function public.admin_activate_request(
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
       and s.duration not in ('unlimited', 'event') and s.ends_at > now()
       and (s.snapshot->>'code') is null;
    insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, addons,
                                              starts_at, ends_at, created_by)
    values (v_request.account_id, v_request.pack_id, v_request.duration,
            private.billing_pack_snapshot(v_request.pack_id), v_request.addons,
            v_start, private.billing_end(v_start, v_request.duration), auth.uid())
    returning id into v_sub;
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

create function public.admin_refuse_request(p_request_id uuid, p_note text default null)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  update public.billing_requests r
     set status = 'refused', decided_at = now(), decided_by = auth.uid(),
         note = nullif(trim(left(p_note, 300)), '')
   where r.id = p_request_id and r.status = 'pending';
  if not found then
    raise exception 'billing_request_not_found'
      using errcode = '55000', detail = 'Demande introuvable ou déjà traitée.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_request_refused', 'billing_request', p_request_id, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_refuse_request(uuid, text) from public, anon;
grant execute on function public.admin_refuse_request(uuid, text) to authenticated;

-- Abonnement offert (motif obligatoire), sans paiement.
create function public.admin_grant_subscription(
  p_account_id uuid,
  p_pack_id uuid,
  p_duration text,
  p_note text,
  p_addons jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_snapshot jsonb;
  v_id uuid;
begin
  perform private.require_platform_admin();
  if p_note is null or char_length(trim(p_note)) < 3 then
    raise exception 'billing_note_required' using errcode = '22023', detail = 'Indiquez le motif.';
  end if;
  select private.billing_pack_snapshot(p.id) into v_snapshot
    from public.billing_packs p where p.id = p_pack_id and p.system = 'flat';
  if v_snapshot is null or p_duration not in ('month', 'quarter', 'semester', 'year', 'event', 'unlimited')
     or not exists (select 1 from public.profiles pr where pr.id = p_account_id) then
    raise exception 'billing_pack_invalid' using errcode = '22023', detail = 'Compte, pack ou durée invalide.';
  end if;
  perform private.billing_addons_cost(v_snapshot, coalesce(p_addons, '{}'::jsonb), 1);
  insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, addons,
                                            starts_at, ends_at, created_by, note)
  values (p_account_id, p_pack_id, p_duration, v_snapshot, coalesce(p_addons, '{}'::jsonb),
          now(), private.billing_end(now(), p_duration), auth.uid(), left(trim(p_note), 300))
  returning id into v_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_granted', 'billing_subscription', v_id,
          jsonb_build_object('duration', p_duration));
  return v_id;
end;
$$;
revoke all on function public.admin_grant_subscription(uuid, uuid, text, text, jsonb) from public, anon;
grant execute on function public.admin_grant_subscription(uuid, uuid, text, text, jsonb) to authenticated;

create function public.admin_cancel_subscription(p_subscription_id uuid, p_note text)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
  perform private.require_platform_admin();
  if p_note is null or char_length(trim(p_note)) < 3 then
    raise exception 'billing_note_required' using errcode = '22023', detail = 'Indiquez le motif.';
  end if;
  update public.billing_subscriptions s
     set status = 'cancelled', cancelled_at = now(), note = left(trim(p_note), 300)
   where s.id = p_subscription_id and s.status = 'active';
  if not found then
    raise exception 'billing_subscription_missing'
      using errcode = '55000', detail = 'Abonnement introuvable ou déjà annulé.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_subscription_cancelled', 'billing_subscription',
          p_subscription_id, '{}'::jsonb);
end;
$$;
revoke all on function public.admin_cancel_subscription(uuid, text) from public, anon;
grant execute on function public.admin_cancel_subscription(uuid, text) to authenticated;

create function public.admin_mark_invoice_paid(
  p_invoice_id uuid,
  p_channel text,
  p_operator_reference text default null,
  p_paid_at timestamptz default null,
  p_note text default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_invoice public.billing_invoices;
begin
  perform private.require_platform_admin();
  select i.* into v_invoice from public.billing_invoices i where i.id = p_invoice_id for update;
  if not found or v_invoice.status <> 'due' then
    raise exception 'billing_invoice_not_found'
      using errcode = '55000', detail = 'Facture introuvable ou déjà réglée.';
  end if;
  perform private.billing_record_payment(v_invoice.account_id, v_invoice.amount, p_channel,
                                         p_operator_reference, p_paid_at, p_note, null, v_invoice.id);
  update public.billing_invoices i
     set status = 'paid', paid_at = coalesce(p_paid_at, now())
   where i.id = p_invoice_id;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.billing_invoice_paid', 'billing_invoice', p_invoice_id,
          jsonb_build_object('amount', v_invoice.amount, 'channel', p_channel));
end;
$$;
revoke all on function public.admin_mark_invoice_paid(uuid, text, text, timestamptz, text) from public, anon;
grant execute on function public.admin_mark_invoice_paid(uuid, text, text, timestamptz, text) to authenticated;

-- Émettre tout de suite la facture d'un événement à l'usage.
create function public.admin_issue_invoice(p_event_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  perform private.require_platform_admin();
  v_id := private.billing_issue_invoice(p_event_id);
  if v_id is null then
    raise exception 'billing_invoice_not_found'
      using errcode = '55000', detail = 'Cet événement n''est pas facturé à l''usage.';
  end if;
  return v_id;
end;
$$;
revoke all on function public.admin_issue_invoice(uuid) from public, anon;
grant execute on function public.admin_issue_invoice(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Packs du système
-- -----------------------------------------------------------------------------
-- Découverte : pack gratuit des comptes sans abonnement. Aucune option
-- réglée = tout illimité et compris, comme aujourd'hui ; ses limites seront
-- fixées dans la console (aucune fonctionnalité retirée par cette migration).
insert into public.billing_packs (code, name, description, system, status, sort_order, durations)
values ('decouverte', 'Découverte', 'Pack gratuit pour démarrer.', 'flat', 'published', 0,
        '{"unlimited": 0}'::jsonb);

-- Lancement : tout compris, offert 3 mois aux comptes existants, jamais
-- proposé à l'achat.
insert into public.billing_packs (code, name, description, system, status, sort_order, durations)
values ('lancement', 'Lancement', 'Tout compris, offert aux premiers promoteurs.', 'flat', 'archived', 0,
        '{"quarter": 0}'::jsonb);

insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, starts_at, ends_at, note)
select o.owner_id, p.id, 'quarter', private.billing_pack_snapshot(p.id),
       now(), now() + interval '3 months', 'Offert aux comptes existants (lancement des packs).'
  from (select distinct owner_id from public.organizations) o
  cross join public.billing_packs p
 where p.code = 'lancement';

-- Les événements qui ont déjà des tickets sont au forfait (comme avant).
update public.events e
   set billing_system = 'flat', billing_locked_at = now()
 where exists (select 1 from public.tickets t where t.event_id = e.id);
