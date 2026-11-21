# ADR 0040 — Événements et tickets depuis la console

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-11, décisions du 21/11 à 18 h 47 ; proposition `claude/proposition-console-admin.md`, sections C et D)

## Contexte

Après les comptes (ADR 0038) et les structures (ADR 0039), la console doit agir sur les événements et les tickets de toute la plateforme, sans jamais afficher ni régénérer un QR (décision 6).

## Décisions

1. **Événements** (permission `events` : modération et super) :
   - liste de tous les événements (recherche titre, ville, structure ; filtre par état), fiche (catégories avec tickets et entrées, portes, totaux, historique) ;
   - **modifier** titre, dates (heure locale de l'événement), lieu, ville, adresse, accroche, description, capacité, public / privé ; jamais un événement clôturé, annulé ou archivé ; les règles de champs sont celles du promoteur ;
   - **changer l'état** selon les transitions du promoteur, plus l'annulation d'un événement en cours ; **annuler** annule les tickets non entrés et prévient leurs détenteurs qui ont ajouté le ticket à « Mes tickets » (`private.cancel_event_tickets`, partagé avec la fermeture de structure) ;
   - **déplacer** vers une autre structure active (erreur de structure à la création), avec catégories, portes et tickets ; les affectations de l'ancienne équipe sont retirées ; jamais un événement déjà facturé ;
   - **corbeille** pour un brouillon sans ticket : invisible des membres (politique `events_visible`), restaurable 30 jours, puis effacé par la tâche nuit `tikeo-trash-purge` (`private.purge_trash`). Un événement qui a des tickets s'annule, il ne s'efface pas.
   - Les catégories et les portes restent gérées par le promoteur (la console les montre) ; la photo aussi. À ajouter si le besoin se présente.
2. **Tickets** (permission `tickets` : support et super ; lecture pour tout administrateur) :
   - recherche sur toute la plateforme par référence, nom (sans accents) ou chiffres du téléphone du titulaire ; fiche : événement, catégorie, état, entrée (heure, porte), envois (canal, date), compte qui l'a dans « Mes tickets » ; **jamais le QR** ;
   - **annuler** un ticket valable (le détenteur est prévenu selon le réglage de la console) ; **changer le titulaire** (mêmes contrôles que pour le promoteur ; le journal ne garde que les champs changés).
3. **Émettre des tickets à la place d'un promoteur** (décision 8) : désactivé par défaut ; possible seulement si le réglage de la console est activé, avec la permission `tickets`. Tickets anonymes d'une catégorie, 1 à 1 000, en un lot visible du promoteur qui les envoie ; le QR n'est pas renvoyé à la console. `private.issue_ticket_rows` (corps de 4500 recopié) admet ce cas.
4. Motifs dans `private.admin_action_log` ; `audit_logs` ne garde que l'action et des champs techniques.

## Conséquences

- Aucun coût ni compte externe.
- À vérifier sur téléphone : annuler un événement de test (message reçu par un détenteur), déplacer un événement, rechercher un ticket par nom, changer son titulaire, l'annuler ; émission après activation du réglage.
