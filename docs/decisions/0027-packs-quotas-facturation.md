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

## Suite : PR 3a — Parcours d'achat du promoteur (20/11/2026)

- Pas de migration : l'app lit `my_billing` et `billing_catalog`, puis appelle `request_billing_pack`, `request_billing_addons`, `declare_billing_payment`, `cancel_billing_request` et `set_organization_billing` (PR 1).
- App (`lib/features/billing/`) : `BillingRepository` (Supabase et faux dépôt), `myBillingProvider`, `billingCatalogProvider`, écrans P1 à P6 sous `/facturation` (Mon pack, choisir un pack forfait ou à l'usage avec simulateur, suppléments, paiement, demande en attente) ; entrée « Mon pack » dans le Profil, pour le propriétaire de la structure.
- Les suppléments en cours d'abonnement affichent une estimation au prorata ; le montant exact est celui que renvoie le serveur avec la demande.
- Reste pour la PR 3b : factures à l'usage (P7), feuille « limite atteinte » et traduction des erreurs `billing_*` (P8), facturation d'un événement (P9), notifications, contrôles de l'app pour l'envoi en série, l'import et la planche A4.

## Suite : PR 3b — Factures, limite atteinte, facturation d'un événement, notifications (20/11/2026)

- Migration `20261120003800_billing_promoter.sql` :
  - **notifications** (file `push_outbox`, langue du compte, aucune donnée personnelle) : pack ou suppléments activés, demande refusée (déclencheur sur `billing_requests`), facture à l'usage émise (déclencheur sur `billing_invoices`), rappel avant la fin d'un abonnement (`reminded_at`, une fois, pas si déjà renouvelé) et facture en retard (`overdue_notified_at`, une fois) par `private.billing_notify`, appelée par `push_tick` ;
  - **jours d'essai** : `start_billing_trial(pack)` (pack forfait publié avec jours d'essai, une fois par compte, pas pendant un abonnement payant), durée `trial` ; un pack payé activé arrête l'essai et démarre tout de suite ; pas de suppléments payants pendant l'essai ;
  - **erreurs de limite lisibles** : HINT en JSON (`limit`, `system`, `event` pour un événement à l'usage) ;
  - `my_billing` v2 : détail des factures (entrées offertes, facturées, suppléments, pack), `trial_used`.
- App :
  - P7 `/facturation/factures` (Toutes, À payer, Payées) et `/facturation/factures/:id` (calcul, échéance, référence `F-XXXXXX`, numéros de paiement, PDF) ;
  - P8 : feuille « Limite atteinte » ouverte automatiquement quand le serveur refuse une action pour le pack (les dépôts appellent `captureBillingBlock`) ; « Dépasser la limite » sur un événement à l'usage, suppléments, packs ou factures selon le cas ; un gestionnaire ou un contrôleur est invité à s'adresser au propriétaire ;
  - P9 `/evenements/:id/facturation` (Comme la structure, Forfait, À l'usage ; figée au premier ticket ; estimation en direct ; facture), entrée « Facturation » dans la fiche de l'événement ;
  - vérifications de l'app : envoi en série, import et planche A4 lisent `event_billing` (un échec de lecture laisse faire) ;
  - tableau de bord en direct non compris : message dans le tableau de bord, sans feuille (il s'actualise toutes les 15 s).
- La référence d'une facture (`F-` + 6 premiers caractères de son identifiant) est calculée par l'app ; la console trouve la facture par l'événement et le montant.
