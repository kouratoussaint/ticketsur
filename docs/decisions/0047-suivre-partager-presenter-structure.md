# ADR 0047 — Suivre une structure, la partager, sa présentation et ses réseaux

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Tout », 22/11 à 12 h 53 ; améliorations n° 5, 6 et 7)

## Décisions

1. **Suivre une structure** : bouton « Suivre / Suivie » sur sa page publique (sans compte : la connexion s'ouvre, puis revient à la page). Le nombre d'abonnés est affiché ; leur liste n'est jamais exposée. 300 structures suivies au plus par compte. Les structures suivies apparaissent dans les Favoris (« N structures suivies » → page `/structures-suivies`).
2. **Notification** : à la **première** mise au catalogue d'un événement (publication d'un événement public, ou passage en public d'un événement publié), chaque abonné qui n'est pas membre de la structure reçoit « Nouvel événement : … » vers la fiche (`/evenement/<id>`, ajoutée aux routes de notification sûres). Une seule fois par événement (`events.followers_notified_at`) ; les événements déjà au catalogue avant la migration ne déclenchent rien. Envoi par la file existante (`push_outbox`, tâche de 5 minutes).
3. **Partager la page d'une structure** : image (statut ou publication) et texte, comme pour un événement (feuille de partage devenue commune).
4. **Présentation et réseaux** : dans « Modifier la structure » (propriétaire), section « Page publique » : présentation (600 caractères) et Facebook, Instagram, TikTok (adresse de la page ou `@nom` du compte, transformé en adresse complète ; seuls ces sites sont acceptés, vérifiés aussi par le serveur). Affichés sur la page publique. Journal : noms des champs modifiés seulement.

## Conséquences

- Migration 5700 : colonnes de présentation et de réseaux, `set_organization_profile`, `my_organizations` recréée, table `organization_followers` (fermée à l'API), `follow_organization`, `my_followed_organizations`, `public_organization` recréée (+ présentation, réseaux, `followers`, `following`), déclencheur `events_notify_followers`.
- Aucun coût ni compte externe.
