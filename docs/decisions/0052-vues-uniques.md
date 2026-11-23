# ADR 0052 — Vues uniques de la fiche publique

- Statut : acceptée
- Date : 23 novembre 2026
- Décideur : Toussaint (« Oui vasy avec 20 », 23/11 à 11 h 48)
- Remplace le point 1 de l'ADR 0051 (comptage)

## Contexte

Depuis l'ADR 0051, l'app n'envoyait qu'une vue par appareil et par jour, mais le serveur comptait chaque appel : un script pouvait gonfler le compteur sans limite.

## Décisions

1. **Le serveur décide** : une vue par visiteur, par événement et par jour (UTC). Le visiteur est le compte connecté ; sinon le numéro d'installation tiré au hasard par l'app (32 caractères, préférence `audience.device`, sans lien avec le téléphone ni le compte) ; sinon (anciennes APK) l'adresse internet.
2. **20 vues au plus par adresse internet**, par événement et par jour : changer de numéro à chaque appel ne suffit plus. Seuil choisi par Toussaint ; assez haut pour les opérateurs mobiles et les cybercafés, qui partagent une même adresse entre beaucoup de personnes.
3. **Les membres de la structure** (propriétaire, gestionnaires, contrôleurs) ne comptent pas.
4. **Vie privée** : ni compte, ni numéro, ni adresse en clair. Seulement une empreinte HMAC-SHA-256 avec une clé tirée au hasard chaque jour (`private.view_salts`). Clés et empreintes (`private.event_view_seen`, `private.event_view_networks`) sont effacées à la première vue du jour suivant et chaque nuit (`private.purge_trash`, tâche `tikeo-trash-purge`). Seul reste le nombre de vues par jour (`event_page_views`).
5. Migration 6200 : `record_event_view(événement, numéro facultatif)` remplace la version à un paramètre (les APK installées continuent de fonctionner).

## Limites

- Quelqu'un qui dispose de nombreuses connexions internet peut encore ajouter des vues, 20 au plus par connexion et par jour.
- Protection complète possible plus tard avec l'API Play Integrity de Google (projet Google Cloud, app sur le Play Store) : à décider avec la mise en production.
