# ADR 0030 — Attribuer une structure à un compte depuis la console

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (demande du 20/11/2026, #10)
- Référence : doc du projet `claude/ameliorations-2026-11-20.md`, PR 4 — Texte et console

## Contexte

L'équipe Tikéo doit pouvoir régler à la main l'appartenance d'un compte à une structure : céder une structure à un nouveau propriétaire, ajouter un gestionnaire ou un contrôleur qui n'arrive pas à utiliser un code d'invitation, corriger un rôle.

## Décisions

1. **Console → Comptes → « Attribuer une structure »** : structure (recherche), rôle, motif obligatoire. Les structures actuelles du compte sont affichées (`admin_account_structures`).
2. **`admin_assign_organization(compte, structure, rôle, motif)`**, réservée aux administrateurs de la plateforme :
   - **Propriétaire = transfert** : `organizations.owner_id` change, l'ancien propriétaire reste dans l'équipe comme **gestionnaire** ; le quota « structures » du pack du nouveau propriétaire est vérifié (erreur `billing_limit_structures`) ; la facturation de la structure suit désormais le pack du nouveau propriétaire ;
   - **Gestionnaire / Contrôleur** : ajout à l'équipe ou changement de rôle (la limite « membres par structure » du pack s'applique comme pour une invitation) ;
   - le propriétaire actuel ne change de rôle que par un transfert à un autre compte (`owner_role_locked`) ; compte désactivé ou supprimé refusé (`account_inactive`).
3. **Motif** gardé dans la table privée `private.organization_assignments` (avec l'ancien propriétaire, l'auteur et la date), jamais dans `audit_logs` (texte libre). Le journal reçoit `admin.organization_assigned` avec seulement le rôle et `transfer`.
4. **Notifications** au compte attribué et, pour un transfert, à l'ancien propriétaire, dans leur langue, ouvrant le Profil (`/profil` ajouté aux routes de notification autorisées).

## Conséquences

- Aucun coût ni compte externe.
- Les affectations aux événements ne changent pas ; un transfert ne retire personne de l'équipe.
