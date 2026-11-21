# ADR 0038 — Rôles d'administration et gestion des comptes depuis la console

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-11, décisions du 21/11 à 18 h 47)

## Contexte

La console ne permettait que de désactiver, réactiver, attribuer une structure et supprimer à échéance. Toussaint veut pouvoir créer, modifier et supprimer les comptes (puis structures, événements) depuis la console, avec des rôles distincts pour les personnes qui l'aideront. Le lot 4-11 est découpé en quatre PR ; celle-ci (4-11a) pose les fondations et traite les comptes.

## Décisions

1. **Quatre rôles**, appliqués par le serveur (migration 4900, table `private.platform_admin_roles`) :
   - **super** : tout, dont les administrateurs et les réglages de la console ;
   - **support** : comptes, structures, suspension des structures, tickets, support ;
   - **modération** : suspension des structures, événements, catalogue et « À la une », annonces ;
   - **finance** : packs, paiements, factures, abonnements.
   Les administrateurs existants deviennent super. Chaque fonction de la console porte sa permission (paramètre de fonction `application_name = 'tikeo.perm:<permission>'`, car Supabase refuse d'attacher un paramètre personnalisé à une fonction) ; sans elle, `admin_role_forbidden`. Il reste toujours au moins un super administrateur (`last_super_admin`).
2. **Double authentification exigée** (`admin_mfa_needed`) pour créer ou supprimer un compte, donner ou retirer un rôle, retirer la double authentification d'un autre administrateur (et, au lot 4-11b, supprimer une structure).
3. **Compte d'un administrateur** : seul un super administrateur agit dessus (`account_admin_protected`). Personne n'agit sur son propre compte depuis la console (`self_forbidden`).
4. **Motif obligatoire** (3 à 500 caractères) pour chaque action ; il est gardé dans `private.admin_action_log`, visible sur la fiche du compte, **jamais** dans `audit_logs` (qui ne reçoit que l'action et des champs techniques).
5. **Création d'un compte avec mot de passe provisoire** (l'invitation par e-mail viendra plus tard) : fonction Edge `admin-accounts` (actions `create`, `password`, `email`). Elle vérifie les droits avec le jeton de l'appelant (`admin_account_guard`), fait l'opération Auth avec la clé de service fournie par Supabase à la fonction (jamais dans l'application), puis consigne avec le jeton de l'appelant. Le mot de passe (`XXXX-XXXX-XXXX`) est affiché une seule fois ; `profiles.must_change_password` impose à la personne de choisir le sien à la connexion avant tout le reste.
6. **Prévenir la personne** : non par défaut ; réglage de la console « Prévenir la personne par défaut » (super administrateur), et case modifiable à chaque action. La notification contient le motif.
7. **Émettre des tickets à la place d'un promoteur** : non par défaut ; réglage de la console posé maintenant, utilisé au lot 4-11c.
8. **Régénération du QR d'un ticket** : non (QR inchangé).
9. **Suppression immédiate** d'un compte : saisie exacte de son adresse e-mail, puis même anonymisation que la suppression à échéance (`private.purge_account`).
10. **Fermeture d'une structure ayant des tickets** (lot 4-11b) : les tickets non entrés des événements à venir sont annulés et leurs détenteurs prévenus.

## Conséquences

- Aucun coût ni compte externe : fonctions Edge et Auth inclus dans Supabase.
- La fonction `admin-accounts` est déployée par le workflow de staging ; aucun secret ajouté au dépôt ni à l'application.
- À vérifier sur téléphone : création d'un compte puis première connexion (choix du mot de passe), mot de passe provisoire, changement d'e-mail, rôle support (actions limitées), suppression immédiate.
