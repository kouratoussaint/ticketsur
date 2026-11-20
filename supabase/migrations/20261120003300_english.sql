-- =============================================================================
-- Tikéo — Application en anglais, côté serveur (lot 4-4b, ADR 0023)
-- =============================================================================
-- * Notifications écrites dans la langue de leur destinataire
--   (profiles.locale, tenu à jour par l'application).
-- * Mentions légales en français et en anglais : version anglaise proposée,
--   modifiable depuis la console comme la française. Sans version dans la
--   langue demandée, la version française est servie.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Notifications
-- -----------------------------------------------------------------------------
create or replace function private.push_on_support_message()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.from_admin then
    insert into public.push_outbox (user_id, title, body, route)
    select r.user_id,
           case p.locale when 'en' then 'Tikéo support' else 'Support Tikéo' end,
           case p.locale when 'en' then 'New reply: ' else 'Nouvelle réponse : ' end || r.subject,
           '/support/' || r.id
      from public.support_requests r
      join public.profiles p on p.id = r.user_id
     where r.id = new.request_id;
  end if;
  return new;
end;
$$;

create or replace function private.push_on_control_started()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'in_progress' and old.status is distinct from 'in_progress' then
    insert into public.push_outbox (user_id, title, body, route)
    select distinct a.user_id,
           case p.locale when 'en' then 'Check open' else 'Contrôle ouvert' end,
           new.title || case p.locale when 'en' then ': you can scan.' else ' : vous pouvez scanner.' end,
           '/postes?evenement=' || new.id
      from public.event_assignments a
      join public.organization_members m
        on m.user_id = a.user_id and m.organization_id = new.organization_id and m.active
      join public.profiles p on p.id = a.user_id
     where a.event_id = new.id and a.active and m.role = 'controller';
  end if;
  return new;
end;
$$;

create or replace function public.send_test_push()
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.require_wallet_user();
  v_locale text;
begin
  if not exists (select 1 from public.push_devices d where d.user_id = v_actor) then
    raise exception 'push_no_device' using errcode = 'P0002',
      detail = 'Aucun téléphone enregistré pour ce compte.';
  end if;
  if (select count(*) from public.push_outbox o
       where o.user_id = v_actor and o.route = '/parametres'
         and o.created_at > now() - interval '1 hour') >= 5 then
    raise exception 'push_test_rate_limited' using errcode = '54000',
      detail = 'Trop d''essais : réessayez dans une heure.';
  end if;
  select p.locale into v_locale from public.profiles p where p.id = v_actor;
  insert into public.push_outbox (user_id, title, body, route)
  values (v_actor, 'Tikéo',
          case v_locale when 'en' then 'Notifications work on this phone.'
                        else 'Les notifications fonctionnent sur ce téléphone.' end,
          '/parametres');
end;
$$;

-- -----------------------------------------------------------------------------
-- Mentions légales par langue
-- -----------------------------------------------------------------------------
alter table public.legal_documents
  add column locale text not null default 'fr' check (locale in ('fr', 'en'));
alter table public.legal_documents drop constraint legal_documents_pkey;
alter table public.legal_documents add primary key (slug, locale);

drop function public.legal_document(text);
create function public.legal_document(p_slug text, p_locale text default 'fr')
returns table (slug text, title text, body text, version integer, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select d.slug, d.title, d.body, d.version, d.updated_at
    from public.legal_documents d
   where d.slug = p_slug and d.locale in (coalesce(p_locale, 'fr'), 'fr')
   order by (d.locale = coalesce(p_locale, 'fr')) desc
   limit 1
$$;
revoke all on function public.legal_document(text, text) from public;
grant execute on function public.legal_document(text, text) to anon, authenticated;

drop function public.admin_save_legal_document(text, text, text);
create function public.admin_save_legal_document(
  p_slug text,
  p_title text,
  p_body text,
  p_locale text default 'fr'
)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := trim(coalesce(p_title, ''));
  v_body text := trim(coalesce(p_body, ''));
  v_locale text := coalesce(p_locale, 'fr');
  v_version integer;
begin
  perform private.require_platform_admin();
  if v_locale not in ('fr', 'en') then
    raise exception 'legal_locale_invalid' using errcode = '22023', detail = 'Langue inconnue.';
  end if;
  if char_length(v_title) not between 3 and 80 then
    raise exception 'legal_title_invalid' using errcode = '22023', detail = 'Titre de 3 à 80 caractères.';
  end if;
  if char_length(v_body) not between 20 and 20000 then
    raise exception 'legal_body_invalid' using errcode = '22023', detail = 'Texte de 20 à 20 000 caractères.';
  end if;
  if p_slug not in ('terms', 'privacy') then
    raise exception 'legal_not_found' using errcode = 'P0002', detail = 'Document inconnu.';
  end if;
  insert into public.legal_documents (slug, locale, title, body, version, updated_at, updated_by)
  values (p_slug, v_locale, v_title, v_body, 1, now(), auth.uid())
  on conflict (slug, locale) do update
    set title = excluded.title, body = excluded.body,
        version = public.legal_documents.version + 1,
        updated_at = now(), updated_by = auth.uid()
  returning version into v_version;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.legal_updated', 'legal_document', null,
          jsonb_build_object('document', p_slug, 'version', v_version, 'locale', v_locale));
  return v_version;
end;
$$;
revoke all on function public.admin_save_legal_document(text, text, text, text) from public, anon;
grant execute on function public.admin_save_legal_document(text, text, text, text) to authenticated;

-- Textes anglais proposés (version 1), à relire et compléter depuis la
-- console, comme les textes français.
insert into public.legal_documents (slug, locale, title, body) values
('terms', 'en', 'Terms of use', $terms$Last updated: see the date at the bottom of the page.

These terms govern the use of the Tikéo app, published by [company name], [address], Burkina Faso (contact: [email address]). By creating an account or using the app, you accept them. In case of difference with the French version, the French version prevails.

## 1. The service
Tikéo lets you discover events and lets event promoters issue QR code tickets, send them and check entries. Tikéo is a tool: each promoter remains solely responsible for their events, their prices, how they are run and any refunds.

## 2. Accounts
- You provide accurate information and keep your password secret.
- An account is personal. You are responsible for what is done with it.
- A promoter can invite members into their organization (managers, controllers) and remains responsible for their actions.

## 3. Tickets and checks
- Each ticket carries a unique QR code, valid for a single entry.
- A ticket already used, cancelled or expired is refused at the entrance.
- Validation is done online. Tikéo does not guarantee mobile network availability at the event venue.
- Copying, reselling or forging a ticket is forbidden.

## 4. Published content
Promoters are responsible for the texts, images and information they publish. Illegal, misleading or hateful content, or content infringing the rights of others, is forbidden. Tikéo may remove an event from the public catalog or suspend an organization in case of breach.

## 5. Availability
We do our best to keep the app running at all times, without being able to guarantee it. Interruptions may occur for maintenance; they are announced in the app when possible.

## 6. Liability
Tikéo cannot be held responsible for an event that is cancelled, postponed or badly organized, nor for a loss caused by misuse of the app. Our liability is limited to direct damage caused by a fault on our part.

## 7. Suspension and deletion
You can delete your account from your Profile; the deletion becomes final after 30 days. We may suspend an account or an organization that does not respect these terms.

## 8. Paid offers
Some features may become paid. Prices and conditions will be presented before any payment.

## 9. Changes
These terms may change. The version in force is always shown in the app, with its date.

## 10. Applicable law
These terms are governed by the law of Burkina Faso. In case of dispute, an amicable solution will be sought before any action before the competent courts of [city].$terms$),
('privacy', 'en', 'Privacy policy', $privacy$Last updated: see the date at the bottom of the page.

This policy explains which data Tikéo processes, why, and how you can exercise your rights, in accordance with Law No. 001-2021/AN of 30 March 2021 on the protection of individuals with regard to the processing of personal data. In case of difference with the French version, the French version prevails.

Data controller: [company name], [address], Burkina Faso. Contact: [email address].

## 1. Data processed
- Account: name, email address, phone (optional), profile photo (optional).
- Organization: name, public WhatsApp number, logo, members and roles.
- Events: information entered by the promoter (title, dates, venue, photo, description, categories).
- Named tickets: holder's name, phone and email, entered by the promoter.
- Checks: date, time, gate and result of each scan.
- Support: your requests and our replies.
- On your phone only: favorites, settings, hidden announcements.

## 2. Why
- To provide the service: accounts, tickets, sending, entry checks, dashboard.
- Security: preventing fraud, keeping a record of sensitive actions.
- To answer you when you write to support.
We do not sell your data and do not show targeted advertising.

## 3. Who has access
- Promoters see the data of their own events and tickets.
- Controllers see the result of scans at their gate.
- The Tikéo team, for assistance and moderation.
- Our technical host (Supabase), which stores the data on our behalf.
A ticket's QR code contains no personal data.

## 4. Retention period
Data is kept as long as the account exists. After a deletion request, the account is anonymized after 30 days; tickets and entry history remain, without names or contact details. [Retention period of support requests to be specified.]

## 5. Security
Encrypted exchanges, data access limited by role, log of sensitive actions without personal data.

## 6. Your rights
You can request access to your data, its correction or deletion, and object to processing, by writing to [email address] or via Profile › Help and support. You can also refer the matter to the Commission de l'informatique et des libertés (CIL) of Burkina Faso.

## 7. Changes
This policy may change. The version in force is always shown in the app, with its date.$privacy$);
