# ADR 0039 — Structures depuis la console : fermeture et corbeille

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-11, décisions du 21/11 à 18 h 47 ; proposition `claude/proposition-console-admin.md`)

## Contexte

Après les comptes (ADR 0038), la console doit créer, modifier et supprimer une structure, et en gérer les membres. Une structure qui a servi porte des tickets, des entrées et des factures : on ne l'efface pas.

## Décisions

1. **Fiche d'une structure** (`admin_organization_detail`) : informations, propriétaire, membres, invitations en cours (4 derniers caractères du code seulement), 20 derniers événements avec tickets et entrées, totaux, pack du propriétaire, factures, historique des actions de la console avec leur motif.
2. **Créer** une structure pour un compte actif (`admin_create_organization`), au pack de ce compte : le quota « structures » du pack s'applique (`billing_limit_structures`). Le choix d'un autre pack se fait par la facturation existante.
3. **Modifier** nom, ville, téléphone, e-mail de contact, numéro WhatsApp public ; **retirer le logo** (le fichier reste au stockage, comme la photo d'un compte supprimé).
4. **Membres** : changer le rôle (gestionnaire ou contrôleur), retirer, annuler une invitation ; ajouter un compte et transférer la propriété passent par `admin_assign_organization` (ADR 0030). Le propriétaire ne se modifie pas directement.
5. **Supprimer** (permission `organizations_delete`, super administrateur seulement, double authentification, nom de la structure à recopier) :
   - **structure vide** (aucun événement, donc aucune facture) : **corbeille** (suspendue, `trashed_at`), restaurable pendant 30 jours, puis **effacée** : nom remplacé par « Structure supprimée », coordonnées, membres, invitations et réglages effacés ; la ligne reste pour le journal ;
   - **structure qui a servi** : **fermeture définitive** (`closed_at`, suspendue pour toujours) : événements à venir ou en cours **annulés**, autres événements archivés, **tickets non entrés des événements annulés annulés**, **détenteurs prévenus** dans l'app (un message par détenteur et par événement, toujours, décision 3), invitations annulées, factures gardées. Les membres perdent l'accès, comme pour une suspension (pas de lecture seule pour le promoteur : simplification assumée, les données restent dans la console).
   - Avant de confirmer, la console montre ce qui sera annulé (`admin_organization_delete_preview`).
6. **Corbeille** (`admin_trash`, page Console › Corbeille) : restauration (support et super), effacement immédiat (super, double authentification) ; effacement automatique chaque nuit (`pg_cron`, tâche `tikeo-trash-purge`, `private.purge_due_organizations`). Les événements rejoindront la corbeille au lot 4-11c.
7. Une structure fermée ou à la corbeille ne peut être ni réactivée, ni modifiée, ni recevoir un membre actif (déclencheur `organization_members_guard`).
8. Motifs dans `private.admin_action_log` ; `audit_logs` ne reçoit que l'action et des champs techniques (champs modifiés, compteurs). Personne concernée prévenue selon le réglage de la console (ADR 0038).

## Conséquences

- Aucun coût ni compte externe.
- `admin_organizations` renvoie `closed_at` et n'affiche plus les structures à la corbeille ou effacées.
- À vérifier sur téléphone : création d'une structure pour un compte, ajout d'un membre, fermeture d'une structure avec tickets (message reçu par un détenteur), corbeille et restauration.
