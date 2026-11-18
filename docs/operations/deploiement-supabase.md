# Déploiement de la base sur Supabase

## Environnements

| Environnement | Projet Supabase | Déploiement |
| --- | --- | --- |
| local / CI | PostgreSQL 16 + shim (`scripts/db-test.sh`) | à chaque PR (`db-tests`) |
| staging | `mbngkfhselqyaopyfphn` | `deploy-staging` à chaque fusion sur `main` touchant `supabase/migrations/`, ou lancement manuel |
| production | à créer | `deploy-production`, après approbation (Phase 6) |

L'URL et la clé **publishable** d'un projet sont publiques par nature (elles sont dans l'APK) ; la sécurité repose sur la RLS et les fonctions serveur. La clé `service_role`, le mot de passe de la base et les jetons d'accès ne quittent jamais Supabase et les environnements protégés GitHub.

## Mise en place du staging (une seule fois)

1. **Jeton d'accès Supabase** : supabase.com → avatar → *Account preferences* → *Access Tokens* → *Generate new token*, nommé `ticketsur-github-staging`. Copier la valeur (affichée une seule fois).
2. **Mot de passe de la base** : celui choisi à la création du projet. S'il est perdu : *Project Settings* → *Database* → *Reset database password*.
3. **Environnement GitHub** : dépôt → *Settings* → *Environments* → *New environment* `staging`. Dans *Environment secrets*, ajouter :
   - `SUPABASE_ACCESS_TOKEN` = le jeton de l'étape 1 ;
   - `SUPABASE_DB_PASSWORD` = le mot de passe de l'étape 2.

   Optionnel : *Required reviewers* pour approuver chaque déploiement.
4. **Premier déploiement** : fusionner la PR qui introduit les migrations, ou *Actions* → `deploy-staging` → *Run workflow* (disponible une fois le workflow présent sur `main`). Fait le 2026-11-18 : migrations 0100, 0200 et 0300 appliquées.

Supabase CLI 3.x vise la base **locale** par défaut : le workflow passe `--remote`, et `--yes` pour l'application (la simulation `--dry-run` la précède toujours).

## Ce que crée le premier déploiement

- Migrations `0100` (schéma, RLS), `0200` (émission, révocation, validation des scans), `0300` (clés Vault).
- Deux secrets Vault, `ticketsur_qr_hmac_key` et `ticketsur_qr_encryption_key`, **générés par le serveur** : leur valeur n'apparaît ni dans le dépôt ni dans les journaux.

## Vérifier après déploiement

Automatique : la dernière étape de `deploy-staging` exécute `scripts/smoke-public-api.sh`, qui se fait passer pour un visiteur anonyme muni de la clé publishable et vérifie qu'il ne peut lire ni écrire aucune table, ni appeler les fonctions d'émission et de scan, ni atteindre le schéma `private`.

Note : Supabase affiche le projet comme « production » (c'est la branche principale du projet, au sens de Supabase) ; pour TicketSûr, c'est l'environnement de **staging**.

Contrôles connectés : le workflow `staging-tests` (après chaque déploiement réussi, ou à la demande) se connecte à la base avec le mot de passe de l'environnement GitHub et :

- vérifie qu'aucune table publique n'est sans RLS, qu'`anon` n'a aucun droit, que les fonctions `security definer` fixent leur `search_path`, et que les deux clés Vault existent (noms et longueurs seulement) ;
- crée comptes, organisations, événements et billets de test **dans une transaction**, rejoue les tests d'acceptation sous le rôle `authenticated`, puis annule tout : aucune donnée ne subsiste.

À l'œil, dans le tableau de bord :

- *Table Editor* : tables `organizations`, `events`, `tickets`, `scan_attempts`… avec RLS active (cadenas).
- *Integrations* → *Vault* : les deux secrets ci-dessus.
- *Advisors* → *Security Advisor* : aucune alerte critique.

## Règles

- Une migration fusionnée n'est jamais modifiée : on en ajoute une nouvelle.
- Ne jamais faire tourner `ticketsur_qr_hmac_key` sans plan de ré-émission : tous les billets existants deviendraient inconnus.
- Les tables créées dans `public` reçoivent par défaut des droits Supabase pour `anon` et `authenticated` : chaque migration qui crée une table doit révoquer ces droits puis accorder explicitement le strict nécessaire, et activer la RLS.
