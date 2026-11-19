# ADR 0017 — Support par formulaire et annonces ciblées

- Statut : acceptée
- Date : 19 novembre 2026
- Décideur : Toussaint (« 1. formulaire ; 2. on choisit les destinataires »)

## Contexte

La console (ADR 0016 et lots 3a-1, 3a-2) permet de modérer les structures, le catalogue et les comptes. Il manquait deux liens entre l'équipe Tikéo et les utilisateurs : répondre à leurs questions, et leur adresser un message (maintenance, nouveauté). Toussaint a choisi un formulaire dans l'application plutôt qu'un bouton WhatsApp, et des annonces dont on choisit les destinataires.

## Décision

1. **Support** (Profil › Aide et support, tout compte connecté, même désactivé) :
   - une demande = sujet (3 à 120 caractères), catégorie (Question, Problème, Compte, Paiement, Autre) et premier message (2 000 caractères au plus) ;
   - l'échange continue des deux côtés ; une réponse de l'équipe passe la demande à « Répondu », un message de l'utilisateur la remet « En attente » ou la rouvre si elle était fermée ;
   - chacun peut fermer la demande ;
   - les réponses de l'équipe apparaissent sous le nom « Support Tikéo », jamais sous le nom de l'administrateur ;
   - non lu tenu des deux côtés : pastille dans le Profil pour l'utilisateur, compteur dans la console ;
   - limites : 5 demandes non fermées par compte, 30 messages par heure.
2. **Console › Support** : demandes non lues d'abord, filtres En attente, Répondu, Fermée, Toutes, recherche par sujet, nom ou adresse ; le fil s'ouvre et se lit comme côté utilisateur.
3. **Annonces** (Console › Annonces) :
   - titre (3 à 80), message (1 000 au plus), importance (normale ou importante) et durée (24 h, 7 jours, 30 jours ou sans fin) ;
   - destinataires cochés, au moins un : visiteurs sans compte, comptes classiques (sans structure), promoteurs (propriétaires et gestionnaires d'une structure active), contrôleurs ;
   - un compte membre de plusieurs structures reçoit les annonces de chacun de ses rôles ;
   - affichées en haut de la présentation, de l'Explorer, de l'accueil du promoteur et de l'écran Contrôle ; au plus deux à la fois, les importantes d'abord ;
   - masquables ; l'appareil se souvient des annonces masquées ;
   - retirées à la main ou à la fin de leur durée.
4. **Données** : tables `support_requests`, `support_messages` et `announcements`, sans accès direct (RLS sans politique) ; tout passe par des fonctions `security definer`.
5. **Journal** : `admin.support_replied` (détails vides), `admin.announcement_published` (`audiences`, `level`) et `admin.announcement_archived`. Ni sujet, ni message, ni nom, ni adresse.

## Conséquences

- Pas de notification push : l'utilisateur voit la réponse en ouvrant l'application (pastille du Profil). Les notifications viendront avec un service d'envoi, décision à prendre (coût).
- Le contenu des demandes reste en base, lisible des seuls administrateurs. Une durée de conservation sera à fixer avec la politique de confidentialité.
- Une annonce n'est jamais bloquante : si sa lecture échoue, rien ne s'affiche.
