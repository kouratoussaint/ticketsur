# ADR 0054 — Notifications des événements et barre de notification

- Statut : acceptée
- Date : 23 novembre 2026
- Décideur : Toussaint (23/11, 17 h 32 à 17 h 41 : « Je veux les notifications dans la barre de notification même quand l'appli n'est pas ouverte », « une notification chez tout le monde lorsqu'un nouvel événement a été publié ou s'il y a eu des modifications » ; choix : « Tous, par ville », « Personnes concernées », « Importantes seulement », avec A+B, le réglage « Nouveaux événements », P1 à P10 et P11)

## Décisions (PR 1 de 2)

1. **Nouvel événement au catalogue** (première mise au catalogue) : notification à tous les téléphones, avec ou sans compte, qui ont choisi sa ville dans l'Explorer, et à ceux en « Toutes les villes ». Sujets Firebase `tikeo_city_<ville>` (ville repliée : minuscules, sans accents, `_` à la place du reste ; même calcul dans l'app et dans `private.city_topic`) et `tikeo_city_all`. Message en français (« Nouvel événement à Bobo-Dioulasso », « Titre · 20/06 à 21h00 · Structure »). Les abonnés de la structure gardent leur message personnel.
2. **Réglage « Nouveaux événements »** (Paramètres › Notifications), activé par défaut, sur l'appareil ; il rappelle la ville suivie.
3. **Modifications importantes d'un événement publié** : date ou heure, lieu ou ville, annulation (y compris par le promoteur : P1, P2). Destinataires : détenteurs de tickets ajoutés à « Mes tickets » (dans leur langue, vers « Mes tickets »), abonnés de la structure, téléphones qui l'ont en favori (sujet `tikeo_event_<id>`, favoris à venir, 100 au plus). Pas pour une description ou une photo. Événement privé : détenteurs seulement. Déclencheur différé à la fin de la transaction : une annulation par la console (qui annule les tickets et prévient déjà leurs détenteurs) n'envoie pas de second message aux mêmes personnes.
4. **Étiquette par événement** (`push_outbox.tag` = `evt-<id>`) : les notifications d'un même événement se remplacent dans la barre au lieu de s'empiler.
5. **Barre de notification** : canal Android « Notifications Tikéo » à importance haute (bandeau en haut de l'écran et son), utilisé par Firebase quand l'app est fermée (`channel_id`, canal par défaut du manifeste) ; quand l'app est ouverte, la notification est aussi posée dans la barre (canal `tikeo/notifications`, `MainActivity.showNotification`) et la toucher ouvre la page ; le bandeau en bas d'écran ne sert plus que si la barre est refusée.

## Suite (PR 2)

P3 à P10 (ticket annulé par le promoteur, affectation, invitation acceptée, retrait du catalogue et suspension, limite du pack, et notifications des administrateurs : support, paiement déclaré, signalement) et P11 (« Prévenir » activé par défaut).

## Conséquences

- Aucun coût : les sujets Firebase sont gratuits. Migration 6500.
- Les messages des sujets ne sont pas traduits (comme les annonces).
