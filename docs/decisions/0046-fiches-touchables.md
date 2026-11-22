# ADR 0046 — Fiches touchables : agenda, itinéraire, filtres, même organisateur, Mon ticket

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Tout », 22/11 à 12 h 53, pour les 11 améliorations proposées ; celles-ci sont les n° 1, 2, 3, 4 et 8)

## Décisions

1. **Lieu → itinéraire** : la ligne du lieu de la fiche publique ouvre Google Maps (application ou site) : par la position (`latitude`, `longitude` de `public_event`) si l'organisateur l'a indiquée, sinon par le nom, l'adresse et la ville. Lien `https://www.google.com/maps/…` : aucune clé ni compte.
2. **Date → agenda** : la ligne de la date ouvre l'agenda du téléphone sur un nouvel événement prérempli (titre, début, fin, lieu, description) ; la personne l'enregistre elle-même (`Intent.ACTION_INSERT` sur `CalendarContract.Events`, canal `ticketsur/send`, méthode `calendar`). Aucune permission d'agenda demandée. Aussi sur « Mon ticket ».
3. **Type et ville → Explorer filtré** : la pastille du type ouvre l'Explorer sur ce type (ville choisie gardée) ; une pastille de la ville ouvre l'Explorer sur cette ville (ville mémorisée comme un choix manuel). Le texte cherché est vidé.
4. **« Du même organisateur »** : en bas de la fiche, jusqu'à 3 autres événements à venir de la structure (`public_organization`), « Tout voir » vers sa page au-delà.
5. **Mon ticket** : « Voir la fiche de l'événement » (si l'événement est au catalogue), « Organisé par … » vers la page de la structure, « Ajouter à mon agenda ». Migration 5600 : `my_tickets` renvoie aussi `organization_id` et `event_listed` (`private.is_listed`). Un ancien cache sans ces champs : rien à ouvrir.

## Conséquences

- Aucun coût ni compte externe. Le bouton d'agenda dépend de l'application d'agenda du téléphone (message si aucune).
- Kotlin modifié (`MainActivity.addToCalendar`) : vérifié par la compilation de l'APK en CI.
