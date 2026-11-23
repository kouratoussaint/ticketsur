-- ADR 0055 : notifications P3 à P11 validées par Toussaint le 23/11.
-- P3 ticket annulé par le promoteur → détenteur ; P4 affectation →
-- contrôleur ; P5 nouveau membre → propriétaire ; P6 retrait du catalogue et
-- suspension (console) → propriétaire, avec le motif ; P7 80 % des tickets du
-- pack → propriétaire ; P8 support, P9 paiement déclaré, P10 signalement →
-- administrateurs qui ont la permission ; P11 « Prévenir » activé par défaut.
-- Rien dans `audit_logs`.

-- Administrateurs actifs dont le rôle a la permission.
create function private.notify_admins(
  p_permission text, p_title_fr text, p_title_en text, p_body_fr text, p_body_en text,
  p_route text, p_tag text
)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.push_outbox (user_id, title, body, route, tag)
  select p.id,
         left(case when p.locale = 'en' then p_title_en else p_title_fr end, 120),
         left(case when p.locale = 'en' then p_body_en else p_body_fr end, 240),
         p_route, p_tag
    from public.profiles p
   where p.is_platform_admin and p.status = 'active' and p.deleted_at is null
     and p_permission = any (private.role_permissions(private.admin_role_of(p.id)))
$$;
revoke all on function private.notify_admins(text, text, text, text, text, text, text)
  from public, anon, authenticated;

-- P3 -------------------------------------------------------------------------
-- Différé : une annulation par la console prévient déjà le détenteur (ou
-- l'administrateur a choisi de ne pas le prévenir) ; ici, seulement les
-- annulations faites par la structure.
create function private.notify_ticket_revoked()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events;
begin
  if new.holder_user_id is null or old.status = 'revoked' or new.status <> 'revoked' then
    return null;
  end if;
  select e.* into v_event from public.events e where e.id = new.event_id;
  if private.is_platform_admin()
     and not private.has_org_role(v_event.organization_id,
                                  array['owner', 'manager']::public.member_role[]) then
    return null;
  end if;
  -- Événement annulé dans la même transaction : un seul message (6500).
  if v_event.status = 'cancelled' then return null; end if;
  perform private.notify_user_tagged(new.holder_user_id,
    'Ticket annulé', 'Ticket cancelled',
    'Votre ticket ' || new.public_reference || ' pour « ' || v_event.title
      || ' » a été annulé par l''organisateur.',
    'Your ticket ' || new.public_reference || ' for “' || v_event.title
      || '” was cancelled by the organizer.',
    '/portefeuille', 'tkt-' || new.event_id);
  return null;
end;
$$;
revoke all on function private.notify_ticket_revoked() from public, anon, authenticated;
create constraint trigger tickets_notify_revoked
  after update of status on public.tickets
  deferrable initially deferred
  for each row execute function private.notify_ticket_revoked();

-- P4 -------------------------------------------------------------------------
create function private.notify_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event public.events;
  v_door text;
begin
  if not new.active or (tg_op = 'UPDATE' and old.active) or new.user_id = auth.uid() then
    return null;
  end if;
  select e.* into v_event from public.events e where e.id = new.event_id;
  -- Copie d'un événement (même transaction que sa création) : rien.
  if v_event.created_at = now()
     or v_event.status not in ('draft', 'published', 'in_progress') then
    return null;
  end if;
  select c.name into v_door from public.checkpoints c where c.id = new.checkpoint_id;
  perform private.notify_user_tagged(new.user_id,
    'Nouvelle affectation', 'New assignment',
    'Vous contrôlez « ' || v_event.title || ' » le ' || private.event_when(v_event)
      || coalesce(' (porte : ' || v_door || ')', '') || '.',
    'You check “' || v_event.title || '” on '
      || to_char(v_event.starts_at at time zone coalesce(v_event.timezone, 'UTC'), 'YYYY-MM-DD HH24:MI')
      || coalesce(' (gate: ' || v_door || ')', '') || '.',
    '/postes', 'asg-' || new.event_id);
  return null;
end;
$$;
revoke all on function private.notify_assignment() from public, anon, authenticated;
create trigger event_assignments_notify
  after insert or update of active on public.event_assignments
  for each row execute function private.notify_assignment();

-- P5 -------------------------------------------------------------------------
create function private.notify_new_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid;
  v_org text;
  v_name text;
begin
  if new.role = 'owner' or not new.active or (tg_op = 'UPDATE' and old.active) then
    return null;
  end if;
  select o.owner_id, o.name into v_owner, v_org
    from public.organizations o where o.id = new.organization_id;
  if v_owner is null or v_owner = new.user_id then return null; end if;
  select p.display_name into v_name from public.profiles p where p.id = new.user_id;
  perform private.notify_user_tagged(v_owner,
    'Nouveau membre', 'New member',
    coalesce(v_name, 'Un membre') || ' a rejoint « ' || v_org || ' » comme '
      || case new.role when 'manager' then 'gestionnaire' else 'contrôleur' end || '.',
    coalesce(v_name, 'A member') || ' joined “' || v_org || '” as '
      || case new.role when 'manager' then 'a manager' else 'a controller' end || '.',
    '/equipe', 'mbr-' || new.organization_id);
  return null;
end;
$$;
revoke all on function private.notify_new_member() from public, anon, authenticated;
create trigger organization_members_notify
  after insert or update of active on public.organization_members
  for each row execute function private.notify_new_member();

-- P6 -------------------------------------------------------------------------
create function private.notify_event_blocked()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner uuid;
begin
  if (old.public_blocked_at is null) = (new.public_blocked_at is null) then return null; end if;
  select o.owner_id into v_owner from public.organizations o where o.id = new.organization_id;
  if new.public_blocked_at is not null then
    perform private.notify_user_tagged(v_owner,
      'Événement retiré du catalogue', 'Event removed from the catalog',
      '« ' || new.title || ' » n''est plus visible au catalogue public. Motif : '
        || coalesce(new.public_blocked_reason, '—'),
      '“' || new.title || '” is no longer in the public catalog. Reason: '
        || coalesce(new.public_blocked_reason, '—'),
      '/evenements/' || new.id, 'blk-' || new.id);
  else
    perform private.notify_user_tagged(v_owner,
      'Événement remis au catalogue', 'Event back in the catalog',
      '« ' || new.title || ' » est de nouveau visible au catalogue public.',
      '“' || new.title || '” is visible again in the public catalog.',
      '/evenements/' || new.id, 'blk-' || new.id);
  end if;
  return null;
end;
$$;
revoke all on function private.notify_event_blocked() from public, anon, authenticated;
create trigger events_notify_blocked
  after update of public_blocked_at on public.events
  for each row execute function private.notify_event_blocked();

-- Suspension et réactivation (la fermeture a son propre message).
create function private.notify_organization_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = old.status or new.closed_at is not null or new.trashed_at is not null then
    return null;
  end if;
  if new.status = 'disabled' then
    perform private.notify_user_tagged(new.owner_id,
      'Structure suspendue', 'Organization suspended',
      '« ' || new.name || ' » est suspendue par l''équipe Tikéo. Motif : '
        || coalesce(new.disabled_reason, '—'),
      '“' || new.name || '” was suspended by the Tikéo team. Reason: '
        || coalesce(new.disabled_reason, '—'),
      '/profil', 'org-' || new.id);
  elsif new.status = 'active' then
    perform private.notify_user_tagged(new.owner_id,
      'Structure réactivée', 'Organization reactivated',
      '« ' || new.name || ' » est de nouveau active.',
      '“' || new.name || '” is active again.',
      '/profil', 'org-' || new.id);
  end if;
  return null;
end;
$$;
revoke all on function private.notify_organization_status() from public, anon, authenticated;
create trigger organizations_notify_status
  after update of status on public.organizations
  for each row execute function private.notify_organization_status();

-- P7 -------------------------------------------------------------------------
-- Une alerte par limite et par événement (ou par période) : 80 % atteints.
create table private.billing_alerts (
  account_id uuid not null references public.profiles (id) on delete cascade,
  option_key text not null,
  scope text not null,
  created_at timestamptz not null default now(),
  primary key (account_id, option_key, scope)
);

create function private.notify_ticket_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  v_plan jsonb;
  v_owner uuid;
  v_limit integer;
  v_used bigint;
  v_inserted integer;
begin
  for r in
    select e.id, e.title, o.owner_id
      from (select distinct i.event_id from inserted i) i
      join public.events e on e.id = i.event_id
      join public.organizations o on o.id = e.organization_id
  loop
    v_plan := private.billing_event_plan(r.id);
    v_owner := r.owner_id;
    v_limit := private.billing_limit(v_plan, 'tickets_per_event');
    if v_limit is not null and v_limit > 0 then
      select count(*) into v_used from public.tickets t
       where t.event_id = r.id and t.status <> 'revoked';
      if v_used * 5 >= v_limit * 4 then
        insert into private.billing_alerts (account_id, option_key, scope)
        values (v_owner, 'tickets_per_event', r.id::text) on conflict do nothing;
        get diagnostics v_inserted = row_count;
        if v_inserted > 0 then
          perform private.notify_user_tagged(v_owner,
            'Limite de tickets bientôt atteinte', 'Ticket limit almost reached',
            '« ' || r.title || ' » : ' || v_used || ' tickets sur ' || v_limit
              || ' permis par votre pack.',
            '“' || r.title || '”: ' || v_used || ' of ' || v_limit
              || ' tickets allowed by your pack.',
            '/facturation', 'quota-' || r.id);
        end if;
      end if;
    end if;
    v_limit := private.billing_limit(v_plan, 'tickets_per_period');
    if v_limit is not null and v_limit > 0 and v_plan->>'system' = 'flat' then
      select count(*) into v_used from public.tickets t
        join public.events e on e.id = t.event_id
        join public.organizations o on o.id = e.organization_id
       where o.owner_id = v_owner
         and coalesce(e.billing_system, 'flat') = 'flat'
         and t.issued_at >= (v_plan->>'period_start')::timestamptz
         and (v_plan->>'period_end' is null or t.issued_at < (v_plan->>'period_end')::timestamptz);
      if v_used * 5 >= v_limit * 4 then
        insert into private.billing_alerts (account_id, option_key, scope)
        values (v_owner, 'tickets_per_period', coalesce(v_plan->>'period_start', 'all'))
        on conflict do nothing;
        get diagnostics v_inserted = row_count;
        if v_inserted > 0 then
          perform private.notify_user_tagged(v_owner,
            'Limite de tickets bientôt atteinte', 'Ticket limit almost reached',
            v_used || ' tickets émis sur ' || v_limit || ' permis par votre pack pour la période.',
            v_used || ' of ' || v_limit || ' tickets allowed by your pack for this period.',
            '/facturation', 'quota-period');
        end if;
      end if;
    end if;
  end loop;
  return null;
end;
$$;
revoke all on function private.notify_ticket_quota() from public, anon, authenticated;
create trigger tickets_notify_quota
  after insert on public.tickets
  referencing new table as inserted
  for each statement execute function private.notify_ticket_quota();

-- P8 -------------------------------------------------------------------------
create function private.notify_admins_support()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.support_requests;
  v_first boolean;
begin
  if new.from_admin then return null; end if;
  select r.* into v_request from public.support_requests r where r.id = new.request_id;
  v_first := not exists (select 1 from public.support_messages m
                          where m.request_id = new.request_id and m.id <> new.id);
  perform private.notify_admins('support',
    case when v_first then 'Nouvelle demande de support' else 'Nouvelle réponse au support' end,
    case when v_first then 'New support request' else 'New support reply' end,
    v_request.subject, v_request.subject,
    '/console/support/' || new.request_id, 'sup-' || new.request_id);
  return null;
end;
$$;
revoke all on function private.notify_admins_support() from public, anon, authenticated;
create trigger support_messages_notify_admins
  after insert on public.support_messages
  for each row execute function private.notify_admins_support();

-- P9 -------------------------------------------------------------------------
create function private.notify_admins_payment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.declared_channel is null or old.declared_channel is not distinct from new.declared_channel
     or new.status <> 'pending' then
    return null;
  end if;
  perform private.notify_admins('billing',
    'Paiement déclaré à valider', 'Payment to confirm',
    new.reference || ' · ' || case new.declared_channel when 'orange_money' then 'Orange Money'
                                                        else 'Moov Money' end,
    new.reference || ' · ' || case new.declared_channel when 'orange_money' then 'Orange Money'
                                                        else 'Moov Money' end,
    '/console/encaisser/demande/' || new.id, 'pay-' || new.id);
  return null;
end;
$$;
revoke all on function private.notify_admins_payment() from public, anon, authenticated;
create trigger billing_requests_notify_admins
  after update of declared_channel on public.billing_requests
  for each row execute function private.notify_admins_payment();

-- P10 ------------------------------------------------------------------------
create function private.notify_admins_report()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_title text;
begin
  if new.kind = 'event' then
    select e.title into v_title from public.events e where e.id = new.event_id;
  else
    select o.name into v_title from public.organizations o where o.id = new.organization_id;
  end if;
  perform private.notify_admins('catalog',
    'Nouveau signalement', 'New report',
    case new.kind when 'event' then 'Événement' else 'Structure' end || ' « ' || v_title || ' » · '
      || case new.reason when 'misleading' then 'Informations trompeuses'
                         when 'scam' then 'Arnaque ou faux événement'
                         when 'offensive' then 'Contenu choquant ou haineux'
                         when 'duplicate' then 'Doublon' else 'Autre raison' end,
    case new.kind when 'event' then 'Event' else 'Organizer' end || ' “' || v_title || '” · '
      || case new.reason when 'misleading' then 'Misleading information'
                         when 'scam' then 'Scam or fake event'
                         when 'offensive' then 'Offensive or hateful content'
                         when 'duplicate' then 'Duplicate' else 'Another reason' end,
    '/console/signalements', 'rep-' || coalesce(new.event_id, new.organization_id));
  return null;
end;
$$;
revoke all on function private.notify_admins_report() from public, anon, authenticated;
create trigger content_reports_notify_admins
  after insert on public.content_reports
  for each row execute function private.notify_admins_report();

-- P11 ------------------------------------------------------------------------
update private.console_settings set value = 'true'::jsonb where key = 'notify_users';
