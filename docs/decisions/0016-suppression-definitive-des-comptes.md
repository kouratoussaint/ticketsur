# ADR 0016 — Désactivation et suppression définitive des comptes

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint (suspension des structures, ADR 0015)

## Contexte

Depuis le lot 1, un utilisateur peut demander la suppression de son compte ; elle devient possible 30 jours plus tard. La purge effective attendait la console. Les tickets, scans et journaux font référence à l'auteur (`profiles`) : effacer la ligne casserait ces références et l'historique des structures.

## Décision

1. **Console › Comptes** (administrateurs) :
   - recherche par nom (sans accents) ou par adresse ;
   - filtres Tous, Désactivés, Suppression demandée, À supprimer, Supprimés.
2. **Désactivation** :
   - motif obligatoire, gardé sur le profil et jamais journalisé ;
   - le compte perd tous ses droits dans ses structures (`has_org_role` exige un profil actif) ; il peut toujours consulter l'Explorer ;
   - réactivation possible ;
   - un administrateur ne peut pas agir sur son propre compte.
3. **Suppression définitive**, seulement 30 jours après la demande, compte par compte ou « tous les comptes arrivés à échéance » :
   - les structures dont le compte est propriétaire sont **suspendues** (motif « Compte du propriétaire supprimé. », journal `cause: owner_deleted`) ;
   - appartenances et affectations désactivées ;
   - profil anonymisé (« Compte supprimé », sans téléphone ni photo), `deleted_at` posé ;
   - compte d'authentification vidé : adresse remplacée par `supprime-<id>@supprime.invalid`, métadonnées, mot de passe et téléphone effacés, identités et sessions supprimées, `banned_until = infinity`. Aucune connexion n'est plus possible ;
   - les lignes restent : tickets, scans et journaux gardent un auteur anonyme ;
   - un compte administrateur n'est pas supprimé (retirer d'abord le rôle).
4. **Journal** : `admin.account_status_changed` (`status`) et `admin.account_purged` (`structures_suspended`). Ni nom, ni adresse, ni motif.

## Conséquences

- La photo de profil reste dans le stockage : Supabase interdit la suppression SQL dans `storage.objects`. Un nettoyage par l'API Storage est à prévoir.
- La purge est lancée à la main depuis la console. Une tâche planifiée (pg_cron) pourra l'automatiser plus tard.
- Sur la base de test locale, la table `auth.users` reçoit les colonnes de Supabase Auth utilisées (`last_sign_in_at`, `banned_until`, `encrypted_password`, `phone`).
