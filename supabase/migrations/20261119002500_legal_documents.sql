-- =============================================================================
-- Tikéo — Migration 2500 : mentions légales modifiables (lot 3c-B, ADR 0018)
-- =============================================================================
-- Décision de Toussaint (19/11/2026) : Claude propose les textes, les
-- administrateurs les modifient depuis la console. Deux documents :
-- conditions d'utilisation (`terms`) et politique de confidentialité
-- (`privacy`). Lecture ouverte à tous, y compris sans compte.
--
-- Format du corps : paragraphes séparés par une ligne vide, « ## » pour un
-- intertitre, « - » pour une puce. Les passages entre crochets sont à
-- compléter par l'éditeur.
-- =============================================================================

create table public.legal_documents (
  slug text primary key check (slug in ('terms', 'privacy')),
  title text not null check (char_length(title) between 3 and 80),
  body text not null check (char_length(body) between 20 and 20000),
  version integer not null default 1 check (version >= 1),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles (id) on delete set null
);
alter table public.legal_documents enable row level security;
revoke all on public.legal_documents from anon, authenticated;

-- Lecture d'un document (avec ou sans compte).
create function public.legal_document(p_slug text)
returns table (slug text, title text, body text, version integer, updated_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select d.slug, d.title, d.body, d.version, d.updated_at
    from public.legal_documents d
   where d.slug = p_slug
$$;
revoke all on function public.legal_document(text) from public;
grant execute on function public.legal_document(text) to anon, authenticated;

-- Console : enregistre une nouvelle version ; renvoie le numéro de version.
create function public.admin_save_legal_document(p_slug text, p_title text, p_body text)
returns integer
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_title text := trim(coalesce(p_title, ''));
  v_body text := trim(coalesce(p_body, ''));
  v_version integer;
begin
  perform private.require_platform_admin();
  if char_length(v_title) not between 3 and 80 then
    raise exception 'legal_title_invalid' using errcode = '22023', detail = 'Titre de 3 à 80 caractères.';
  end if;
  if char_length(v_body) not between 20 and 20000 then
    raise exception 'legal_body_invalid' using errcode = '22023', detail = 'Texte de 20 à 20 000 caractères.';
  end if;
  update public.legal_documents d
     set title = v_title, body = v_body, version = d.version + 1,
         updated_at = now(), updated_by = auth.uid()
   where d.slug = p_slug
  returning d.version into v_version;
  if not found then
    raise exception 'legal_not_found' using errcode = 'P0002', detail = 'Document inconnu.';
  end if;
  insert into public.audit_logs (organization_id, actor_id, action, resource_type, resource_id, details)
  values (null, auth.uid(), 'admin.legal_updated', 'legal_document', null,
          jsonb_build_object('document', p_slug, 'version', v_version));
  return v_version;
end;
$$;
revoke all on function public.admin_save_legal_document(text, text, text) from public, anon;
grant execute on function public.admin_save_legal_document(text, text, text) to authenticated;

-- Textes proposés (version 1), à relire et compléter depuis la console.
insert into public.legal_documents (slug, title, body) values
('terms', 'Conditions d''utilisation', $terms$Dernière mise à jour : voir la date en bas de page.

Les présentes conditions encadrent l'utilisation de l'application Tikéo, éditée par [raison sociale], [adresse], Burkina Faso (contact : [adresse e-mail]). En créant un compte ou en utilisant l'application, vous les acceptez.

## 1. Le service
Tikéo permet de découvrir des événements et, pour les promoteurs d'événements, d'émettre des tickets à QR code, de les envoyer et de contrôler les entrées. Tikéo est un outil : chaque promoteur reste seul responsable de ses événements, de leurs prix, de leur tenue et de leurs éventuels remboursements.

## 2. Comptes
- Vous fournissez des informations exactes et gardez votre mot de passe secret.
- Un compte est personnel. Vous êtes responsable de ce qui est fait avec.
- Un promoteur peut inviter des membres dans sa structure (gestionnaires, contrôleurs) et reste responsable de leurs actions.

## 3. Tickets et contrôle
- Chaque ticket porte un QR code unique, valable pour une seule entrée.
- Un ticket déjà utilisé, annulé ou expiré est refusé à l'entrée.
- La validation se fait en ligne. Tikéo ne garantit pas la disponibilité du réseau mobile sur le lieu de l'événement.
- Copier, revendre ou falsifier un ticket est interdit.

## 4. Contenus publiés
Les promoteurs sont responsables des textes, images et informations qu'ils publient. Sont interdits les contenus illégaux, trompeurs, haineux ou portant atteinte aux droits d'autrui. Tikéo peut retirer un événement du catalogue public ou suspendre une structure en cas de manquement.

## 5. Disponibilité
Nous faisons notre possible pour que l'application fonctionne en continu, sans pouvoir le garantir. Des interruptions peuvent avoir lieu pour maintenance ; elles sont annoncées dans l'application quand c'est possible.

## 6. Responsabilité
Tikéo ne peut être tenu responsable d'un événement annulé, reporté ou mal organisé, ni d'une perte liée à une mauvaise utilisation de l'application. Notre responsabilité est limitée aux dommages directs causés par une faute de notre part.

## 7. Suspension et suppression
Vous pouvez supprimer votre compte depuis le Profil ; la suppression devient définitive après 30 jours. Nous pouvons suspendre un compte ou une structure qui ne respecte pas ces conditions.

## 8. Offres payantes
Certaines fonctions pourront devenir payantes. Les prix et conditions seront présentés avant tout paiement.

## 9. Modifications
Ces conditions peuvent évoluer. La version en vigueur est toujours affichée dans l'application, avec sa date.

## 10. Droit applicable
Ces conditions sont soumises au droit burkinabè. En cas de litige, une solution amiable sera recherchée avant toute action devant les tribunaux compétents de [ville].$terms$),
('privacy', 'Politique de confidentialité', $privacy$Dernière mise à jour : voir la date en bas de page.

Cette politique explique quelles données Tikéo traite, pourquoi et comment vous pouvez exercer vos droits, conformément à la loi n°001-2021/AN du 30 mars 2021 portant protection des personnes à l'égard du traitement des données à caractère personnel.

Responsable du traitement : [raison sociale], [adresse], Burkina Faso. Contact : [adresse e-mail].

## 1. Données traitées
- Compte : nom, adresse e-mail, téléphone (facultatif), photo de profil (facultative).
- Structure : nom, numéro WhatsApp public, logo, membres et rôles.
- Événements : informations saisies par le promoteur (titre, dates, lieu, photo, description, catégories).
- Tickets nominatifs : nom, téléphone et e-mail du titulaire, saisis par le promoteur.
- Contrôle : date, heure, porte et résultat de chaque scan.
- Support : vos demandes et nos réponses.
- Sur votre téléphone seulement : favoris, réglages, annonces masquées.

## 2. Pourquoi
- Fournir le service : comptes, tickets, envoi, contrôle des entrées, tableau de bord.
- Sécurité : empêcher la fraude, garder une trace des actions sensibles.
- Vous répondre quand vous écrivez au support.
Nous ne vendons pas vos données et n'affichons pas de publicité ciblée.

## 3. Qui y a accès
- Les promoteurs voient les données de leurs propres événements et tickets.
- Les contrôleurs voient le résultat des scans à leur porte.
- L'équipe Tikéo, pour l'assistance et la modération.
- Notre hébergeur technique (Supabase), qui stocke les données pour notre compte.
Le QR code d'un ticket ne contient aucune donnée personnelle.

## 4. Durée de conservation
Les données sont gardées tant que le compte existe. Après une demande de suppression, le compte est anonymisé au bout de 30 jours ; les tickets et l'historique des entrées restent, sans nom ni coordonnées. [Durée de conservation des demandes de support à préciser.]

## 5. Sécurité
Échanges chiffrés, accès aux données limité selon le rôle, journal des actions sensibles sans données personnelles.

## 6. Vos droits
Vous pouvez demander l'accès à vos données, leur rectification ou leur suppression, et vous opposer à un traitement, en écrivant à [adresse e-mail] ou via Profil › Aide et support. Vous pouvez aussi saisir la Commission de l'informatique et des libertés (CIL) du Burkina Faso.

## 7. Modifications
Cette politique peut évoluer. La version en vigueur est toujours affichée dans l'application, avec sa date.$privacy$);
