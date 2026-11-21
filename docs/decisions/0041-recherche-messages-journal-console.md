# ADR 0041 — Recherche globale, messages ciblés et journal filtrable

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-11, décisions du 21/11 à 18 h 47 ; le 21/11 à 23 h 04 : « n'inclut pas la version minimale »)

## Contexte

Dernière partie de la console complète (`claude/proposition-console-admin.md`, sections E et F). Le lot 4-11d est découpé en deux PR : 4-11d-1 (cet ADR) et 4-11d-2 (maintenance, inscriptions, exports). La **version minimale de l'app** est retirée du lot à la demande de Toussaint.

## Décisions

1. **Recherche globale** (`admin_global_search`, tout administrateur) : un texte de 2 à 60 caractères, cinq résultats au plus par section (comptes, structures, événements, et tickets à partir de 3 caractères), avec les règles de recherche des listes de la console. Entrée en haut de la console, page `/console/recherche`.
2. **Messages ciblés** (`admin_send_message`, permission `support` ou `announcements`) :
   - **à un compte** : conversation du support ouverte par l'équipe (« Support Tikéo »), notification par le déclencheur existant ; la personne peut répondre ;
   - **aux membres actifs d'une structure** ou **aux détenteurs reliés d'un événement** (comptes qui ont le ticket dans « Mes tickets », ticket non annulé) : annonce réservée (`announcements.organization_id` / `event_id`, bandeau dans l'app pendant 1 à 30 jours) et une notification à chacun. Un détenteur sans compte relié ne peut pas être joint (pas de rattachement par téléphone : ADR 0019) ; sans aucun destinataire, l'envoi est refusé (`message_no_recipients`).
   - Un message réservé ne se modifie pas (`announcement_targeted`) ; il s'archive comme une annonce.
   - Le journal garde le public (`account`, `members`, `holders`) et le nombre de destinataires, jamais le texte.
3. **Journal filtrable** : `admin_audit_logs` reçoit les filtres administrateur, compte, structure, événement (les tickets de l'événement compris) et renvoie l'auteur. Boutons « Journal » sur les fiches d'un compte, d'une structure, d'un événement ; filtre « Administrateur » dans le journal. Les anciennes APK appellent toujours avec les trois premiers paramètres.

## Conséquences

- Aucun coût ni compte externe.
- À vérifier sur téléphone : recherche globale, message à un compte (réponse depuis « Support »), message aux membres d'une structure et aux détenteurs d'un événement (notification et bandeau), journal filtré.
