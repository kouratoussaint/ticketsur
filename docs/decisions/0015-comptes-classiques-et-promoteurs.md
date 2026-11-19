# ADR 0015 — Comptes classiques et promoteurs, structures, favoris

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint

## Contexte

Jusqu'ici, un compte connecté devait créer une organisation ou en rejoindre une avant d'entrer dans l'application, et aucun compte ne se créait depuis l'application. Toussaint a revu les parcours le 19/11/2026.

## Décision

1. **Vocabulaire.** « Organisation » devient **structure** (« Nom de la structure ou de l'entreprise » dans les formulaires). « Organisateur » devient **promoteur d'événement**. Le code et la base gardent leurs noms techniques (`organizations`).
2. **Création de compte dans l'application** (`/inscription`) : nom, adresse, mot de passe de 8 caractères au moins.
   - **Par défaut, compte classique** : onglets Explorer, Favoris et Profil. Le Profil propose « Créer ma structure » et « Rejoindre une équipe avec un code ».
   - **« Je suis promoteur d'événement »** coché : le nom de la structure (obligatoire) et le numéro WhatsApp public (facultatif) s'ajoutent au formulaire. La structure est créée dès l'inscription.
   - **Code d'invitation** facultatif : l'équipe est rejointe dès l'inscription. « J'ai un code d'invitation » sur la présentation ouvre l'inscription sur ce champ.
   - Si la confirmation par e-mail est activée, un message invite à confirmer puis à se connecter ; la structure ou le code se font ensuite depuis le Profil. Elle est désactivée sur le staging.
3. **Présentation sans compte** : découvrir les événements (bande d'événements publics, « Voir tous les événements »), puis organiser les siens. L'aperçu des écrans de contrôle est retiré, mais la route de revue reste. Le logo Tikéo figure sur la présentation, la connexion, l'inscription, le mot de passe oublié, la création de structure et le code d'invitation.
4. **Favoris**, avec ou sans compte : un cœur sur les cartes et la fiche publique, gardé sur l'appareil (200 au plus, résumé de l'événement). La liste se trouve dans l'onglet Favoris (sans compte et compte classique) ou sur `/favoris`. Ils ne sont pas encore synchronisés avec le compte.
5. **Événements publics par défaut** (`events.is_public` vaut vrai par défaut, migration 2100). Ils n'apparaissent dans l'Explorer qu'une fois publiés ; le promoteur peut les rendre privés. Les événements existants gardent leur réglage.
6. **Listes du promoteur** :
   - événements en sections En cours, À venir, Brouillons, Passés ;
   - tickets regroupés par type (`event_tickets(..., p_category_id)`).
7. **Retour** : les pages de détail (fiche et tableau de bord d'un événement, création et modification, ticket, import, envoi, profil et fiche de la structure) s'empilent au-dessus des onglets. Retour ramène toujours à l'écran d'où l'on vient.
8. **Rôles côté routeur** :
   - un contrôleur est redirigé vers Contrôle s'il vise une page du promoteur ;
   - un compte classique est redirigé vers l'Explorer s'il vise une page du promoteur ou du contrôle ;
   - un onglet hors du rôle n'est jamais affiché, pas même une image.
9. **Suppression du compte d'un propriétaire** : ses structures sont **suspendues** quand la suppression devient effective (30 jours). Le texte de confirmation l'annonce dès maintenant. La purge elle-même arrive au lot 3a-2.

## Conséquences

- Plus d'écran « Créer votre organisation » imposé à la première connexion.
- Les anciennes APK restent compatibles : `p_category_id` est facultatif, et les colonnes ne changent pas.
