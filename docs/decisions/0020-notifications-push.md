# ADR 0020 — Notifications push par Firebase Cloud Messaging

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (Firebase : oui, ADR 0018 ; projet Firebase créé par lui le 20/11)

## Contexte

Les réponses du support, les annonces importantes et l'ouverture du contrôle n'étaient visibles qu'en ouvrant l'application. Firebase Cloud Messaging est gratuit. Il demande un projet Firebase (créé par Toussaint) et une clé de compte de service pour l'envoi.

## Décision

1. **Secrets** :
   - jamais dans le dépôt ni dans le chat ;
   - `TIKEO_GOOGLE_SERVICES_JSON` (secret du dépôt) : la CI en tire les identifiants publics de l'application (`TIKEO_FB_*`, passés à Dart) ; pas de plugin Gradle Google Services ;
   - `TIKEO_FCM_SERVICE_ACCOUNT` (environnement `staging`) : posé en secret Supabase `FCM_SERVICE_ACCOUNT_B64` par `deploy-staging`.
   - Sans ces secrets, tout fonctionne comme avant, sans notifications.
2. **File d'envoi** (migration 2800) :
   - la base place les messages dans `push_outbox`, par des déclencheurs :
     - réponse de l'équipe du support → le demandeur ;
     - annonce **importante** → sujets Firebase des destinataires choisis ;
     - contrôle démarré → contrôleurs affectés à l'événement ;
   - aucun jeton QR ni contenu dans `audit_logs`.
3. **Envoi** : la fonction Edge `push-dispatch` prend un lot de messages (`push_take_batch`, réservé à `service_role`), les envoie par l'API HTTP v1, puis les marque (`push_mark`).
   - Elle oublie les jetons refusés par Firebase et abandonne un message après 5 essais.
   - L'application l'appelle juste après les actions concernées : réponse au support, annonce importante, démarrage du contrôle. Un appel sans message en attente ne fait rien.
4. **Destinataires** :
   - un compte connecté enregistre le jeton de son téléphone (`push_devices`, un jeton = un compte) ;
   - les annonces passent par des sujets (`tikeo_visitors`, `tikeo_users`, `tikeo_promoters`, `tikeo_controllers`), qui touchent aussi les visiteurs sans compte ;
   - les sujets d'un compte connecté suivent ses structures. Ils sont calculés dans la coque connectée, qui est libérée à la déconnexion.
5. **Téléphone** :
   - autorisation demandée à l'ouverture (Android 13 et plus) ;
   - Paramètres › Notifications pour couper (sujets quittés, jeton oublié) ;
   - message reçu application ouverte : bandeau avec « Voir » ;
   - notification touchée : ouvre la page, si elle figure dans une liste blanche (`/support/<id>`, `/postes?evenement=<id>`).

## Conséquences

- Les messages partent quand l'action a lieu dans l'application. Un message resté en file (réseau coupé) part au prochain appel de la fonction. Une tâche planifiée (pg_cron) pourra les relancer plus tard.
- Le rappel « votre événement commence demain » aux détenteurs de tickets demandera aussi une tâche planifiée.
