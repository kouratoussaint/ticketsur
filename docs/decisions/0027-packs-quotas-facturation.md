# ADR 0027 — Packs, quotas et facturation (base)

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (spécification validée le 20/11/2026, écrans P1 à P9 et C1 à C6 compris ; invitations facturées à l'usage confirmées le 20/11/2026)
- Référence : doc du projet `claude/specification-packs-facturation.md`

## Contexte

Tikéo devient payant pour les promoteurs. Toussaint veut deux systèmes, réglables dans la console sans nouvelle version de l'app :

- **forfait** : un abonnement (mois, trimestre, semestre, année, ou un seul événement) qui ouvre des quotas et des fonctions ;
- **usage** : un prix par entrée réelle, facturé après l'événement.

Les paiements passent par Orange Money et Moov Money, vérifiés à la main par l'administrateur (aucun prestataire de paiement, aucun coût externe). Règle de Toussaint : **aucune fonctionnalité retirée** par cette mise en place.

## Décision

1. **Découpage en trois PR** : base (cette PR), console (écrans C1 à C6), promoteur (écrans P1 à P9 et notifications).
2. **Tout est vérifié côté serveur**, dans la base (migration `3600`) :
   - tables fermées à l'API (`revoke all`), lues et écrites seulement par des fonctions `security definer` ;
   - quotas et fonctions vérifiés par des **déclencheurs** sur les écritures : aucune fonction existante n'a changé de contrat, et une ancienne APK reçoit le même refus qu'une nouvelle ;
   - lectures soumises au pack (rapports pour l'option Export, tableau de bord en direct) : la fonction publique vérifie les droits puis le pack, et appelle le corps existant, déplacé dans `private` ;
   - **jamais à la porte** : le contrôle d'un ticket n'est jamais bloqué par le pack ni par une facture.
3. **Liste fixe des options** (`private.billing_numeric_options`, `private.billing_feature_options`, `BillingOption` dans l'app, vérifiées identiques par un test) :
   - chiffrées : structures, événements actifs, tickets par événement, tickets par période, membres par structure (propriétaire non compté), contrôleurs par événement (personnes distinctes) ;
   - oui / non : envoi assisté, envoi en série, import, export, planche A4, design importé, tickets nominatifs, tableau de bord en direct, catalogue public, support prioritaire.
   - Vérifiées par le serveur dès cette PR : structures, événements actifs, tickets (événement et période), membres, contrôleurs, envoi assisté, export, design importé, tickets nominatifs, tableau de bord, catalogue public. Envoi en série, import, planche A4 et support prioritaire sont des fonctions de l'app : elles lisent `my_billing` / `event_billing` (PR 3).
   - **Option absente d'un pack = illimitée ou comprise** : un oubli dans la console ne retire rien.
4. **Droits d'un événement** :
   - choix par structure (forfait par défaut) et par événement, **figé au premier ticket émis** ;
   - au forfait : abonnement en vigueur du compte (période de grâce comprise), sinon pack gratuit **Découverte** (quotas par mois civil) ;
   - à l'usage : pack copié dans l'événement au premier ticket (une modification du pack ne change pas un événement commencé) ; une facture à l'usage en retard bloque l'émission sur un **nouvel** événement à l'usage seulement.
   - Un abonnement garde une copie du pack à l'activation.
5. **Concurrence** : chaque vérification de quota se fait sous un verrou consultatif **par compte** (`billing:<compte>`), en plus du verrou de l'événement déjà pris à l'émission. Deux émissions sur deux événements différents ne dépassent pas le quota de la période (test `BIL-01`) ; deux créations de structure non plus (`BIL-02`).
6. **Factures à l'usage** :
   - **entrées réelles** = entrées acceptées : chaque entrée d'un pass compte, **les invitations qui entrent sont facturées** (décision du 20/11) ;
   - pas de minimum ; entrées offertes ; paliers marginaux facultatifs ; suppléments « Dépasser la limite » ajoutés à la facture ;
   - émise à la clôture du contrôle, ou par la tâche planifiée (`private.billing_tick`, dans `push_tick`, toutes les 5 minutes) N heures après la fin, ou par l'administrateur ; une facture à 0 FCFA est réglée d'office ;
   - estimation en direct dans `event_billing`.
7. **Demandes et paiements** : le promoteur choisit pack, durée et suppléments (au prorata des jours restants en cours d'abonnement) ; la demande reçoit une référence `TK-XXXX` ; il déclare son paiement (canal, identifiant facultatif). L'administrateur valide (paiement reçu + abonnement ; un renouvellement commence à la fin de l'abonnement en cours) ou refuse. Il peut offrir un abonnement (motif obligatoire), l'annuler, marquer une facture réglée, régler les numéros de paiement et les délais.
8. **Données personnelles** : aucun nom ni numéro de payeur stocké ; dans `audit_logs`, seulement montants, canaux, durées et options (actions `billing.*` et `admin.billing_*`).
9. **Aucune fonctionnalité retirée** :
   - Découverte est créé **sans aucune option réglée**, donc illimité et tout compris, comme aujourd'hui, jusqu'à ce que Toussaint fixe ses limites dans la console (PR 2) ;
   - **Lancement** (tout compris, archivé, jamais proposé à l'achat) est offert 3 mois à chaque compte qui possède une structure au moment de la migration ;
   - les événements qui ont déjà des tickets sont figés au forfait ;
   - les messages de l'app pour les limites atteintes, l'écran « Mon pack » et la console viennent avec les PR 2 et 3 ; d'ici là, rien n'est limité.

## Conséquences

- Les nouvelles limites ne s'appliquent qu'une fois réglées dans la console : la PR 2 doit être prête avant de fixer celles de Découverte, et la PR 3 avant de proposer des packs payants aux promoteurs.
- Les tests SQL (`99_billing.sql`, staging compris) et de concurrence (`run_billing_concurrency.sh`) couvrent quotas, options, demandes, renouvellement, factures, paliers et journal. Les données de test neutralisent les limites de Découverte dans leur transaction, pour rester vertes quel que soit le réglage du staging.
- Ajouter une option = une migration, une valeur dans `BillingOption` et son libellé.

## Suite : PR 2 — Console (20/11/2026)

- Migration `20261120003700_billing_console.sql` :
  - `admin_billing()` en version 2 (mêmes clés, plus `account_email`, `pack_id` et `pack_code` des abonnements, `events` par pack, `history` : 50 dernières demandes traitées et factures payées) ;
  - `admin_extend_subscription(abonnement, fin, motif)`, `admin_change_subscription_pack(abonnement, pack forfait, motif)` (les suppléments doivent exister dans le nouveau pack), `admin_set_subscription_addons(abonnement, suppléments, motif)` (0 = retiré) ;
  - `admin_billing_events(recherche, limite)` et `admin_set_event_billing(événement, 'flat'|'usage', pack usage, motif)` : change la facturation même figée (copie du pack à l'usage refaite, suppléments remis à zéro), refusé avec `billing_invoice_exists` si une facture a été émise ;
  - motif obligatoire (`billing_note_required`, 3 caractères), jamais écrit dans le journal.
- App (`lib/features/billing/`) : `BillingAdminRepository` (Supabase et faux dépôt), `adminBillingProvider`, écrans C1 à C6 sous `/console/packs`, `/console/encaisser`, `/console/abonnements`, `/console/paiement`.
- Le montant reçu saisi en C4 n'est pas stocké à part : `admin_activate_request` enregistre le montant de la demande ; un écart est ajouté à la note du paiement.
- Tests : `99_billing_console.sql` (16 contrôles, staging compris), `test/features/billing/billing_console_test.dart`, audit des contrastes étendu aux écrans de la console.
