# ADR 0044 — Structure fermée : consultation seule

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Oui », 22/11 à 10 h 14, à la question laissée ouverte par l'ADR 0039)

## Contexte

Une structure supprimée depuis la console alors qu'elle a déjà des événements est **fermée** (ADR 0039) : données gardées, événements à venir annulés, plus aucun accès pour son équipe. Son promoteur ne pouvait plus revoir ses événements, ses chiffres ni ses rapports (bilans, comptabilité, litiges).

## Décisions

1. **Qui** : le propriétaire et les gestionnaires encore membres de la structure fermée, avec un compte actif. Pas les contrôleurs. Une structure à la corbeille ou effacée n'est plus consultable.
2. **Quoi** : la liste de ses événements avec leurs chiffres (tickets, entrés, annulés), le bilan PDF et la liste des tickets en CSV de chaque événement (mêmes fichiers que d'habitude), et les factures du compte pour le propriétaire. Rien ne peut être créé, modifié, envoyé ni contrôlé. Pas de limite de pack sur ces exports : les données appartiennent déjà à la structure.
3. **Où** : Profil › « Structures fermées » (ligne visible seulement s'il y en a une) → fiche avec le bandeau « Structure fermée le … : consultation seule ». La structure n'apparaît plus parmi les structures actives.
4. **Comment (serveur, migration 5400)** : fonctions de consultation dédiées (`my_closed_organizations`, `closed_organization_events`, `closed_event_dashboard`, `closed_event_summary`, `closed_event_report_rows`). Chacune vérifie le droit, pose le réglage local `tikeo.closed_read` le temps de relire avec les corps existants, puis le retire ; `private.has_org_role` n'accepte une structure fermée que lorsque ce réglage la désigne. Aucune fonction d'écriture ne le pose et un client ne peut pas le poser : les écritures restent refusées. Les exports restent inscrits au journal comme avant (nombre de lignes seulement).

## Conséquences

- Aucun coût ni compte externe.
- Le message envoyé au propriétaire à la fermeture ne mentionne pas encore la consultation.
- À vérifier sur téléphone : fermer une structure de test depuis la console, puis, avec le compte du propriétaire, ouvrir Profil › Structures fermées, exporter le bilan PDF et la liste CSV d'un événement.
