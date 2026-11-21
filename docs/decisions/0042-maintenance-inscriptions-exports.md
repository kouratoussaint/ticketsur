# ADR 0042 — Maintenance, inscriptions et exports depuis la console

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-11, décisions du 21/11 à 18 h 47 ; version minimale retirée le 21/11 à 23 h 04)

## Contexte

Seconde partie du lot 4-11d (après l'ADR 0041) : pilotage de la plateforme (`claude/proposition-console-admin.md`, section F), sans la version minimale de l'app.

## Décisions

1. **Mode maintenance** (réglage de la console, permission `settings`) :
   - bandeau « Maintenance en cours » pour tous (avec ou sans compte), avec un message facultatif de 300 caractères, affiché avec les annonces ;
   - au besoin, **modifications bloquées** pour les comptes qui ne sont pas administrateurs (`maintenance`, 55000), par des déclencheurs sur les structures, membres, invitations, réglages, catégories, portes, affectations, modèles, demandes de pack, événements (création, suppression, modification) et tickets (émission, annulation, titulaire) ;
   - **jamais bloqués** : la validation à l'entrée, le démarrage et l'arrêt du contrôle (changement d'état d'un événement), « Mes tickets », le support, le profil, les tâches planifiées. Un événement en cours ne doit jamais s'arrêter à cause d'une maintenance.
2. **Inscriptions ouvertes ou fermées** : fermées, un compte ne se crée qu'avec un **code d'invitation valable** d'une structure active (passé à l'inscription, vérifié par le déclencheur de création du profil puis retiré des métadonnées du compte), ou **par un administrateur** depuis la console (`app_metadata.tikeo_admin_created`, posé par la fonction serveur `admin-accounts`, que l'app ne peut pas poser). L'écran d'inscription l'annonce et exige le code.
3. **Exports pour Excel** (`admin_export`) : comptes (`accounts`), structures (`organizations`), événements (`events`), factures (`billing`), journal (tout administrateur). 50 000 lignes au plus, les plus récentes ; CSV en français (`;`, BOM, formules neutralisées) partagé depuis le téléphone. Le journal garde le type d'export et le nombre de lignes, jamais le contenu. Les e-mails des comptes supprimés ne sont pas exportés.
4. **Version minimale de l'app** : retirée du lot à la demande de Toussaint.

## Conséquences

- Aucun coût ni compte externe.
- Un message d'erreur précis « maintenance » n'existe pas encore dans chaque écran : le bandeau l'explique.
- À vérifier sur téléphone : activer la maintenance avec modifications bloquées (bandeau, création d'événement refusée, contrôle à l'entrée qui continue), fermer les inscriptions (inscription avec et sans code), exporter les comptes et ouvrir le CSV dans Excel.
