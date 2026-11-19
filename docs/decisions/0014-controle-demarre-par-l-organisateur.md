# ADR 0014 — Contrôle démarré et arrêté par l'organisateur

- Statut : acceptée (remplace la fenêtre horaire de la migration 0100)
- Date : 19 novembre 2026
- Décideur : Toussaint

## Contexte

Depuis le MVP, un ticket pouvait être validé de 3 heures avant le début de l'événement jusqu'à 6 heures après sa fin (`scan_opens_before`, `scan_closes_after`), dès que l'événement était publié. Sur le terrain, les horaires bougent : les portes ouvrent plus tôt, le contrôle commence en retard ou se prolonge. L'organisateur veut décider lui-même.

## Décision

1. **Plus aucune fenêtre horaire.** Le serveur accepte une entrée seulement si l'événement est au statut « contrôle en cours » (`in_progress`), quelle que soit l'heure.
2. **« Démarrer le contrôle »** (publié → en cours) ouvre les portes immédiatement. Un événement seulement publié n'est pas contrôlable : verdict `event_inactive`.
3. **« Arrêter le contrôle »** (en cours → clôturé) ferme les portes. C'est définitif : on ne revient pas de « clôturé » à « en cours ».
4. Les heures réelles sont enregistrées (`events.control_started_at`, `control_stopped_at`). Le tableau de bord les utilise pour sa chronologie et indique `control_open`.
5. **Les contrôleurs** voient leurs postes pour les événements publiés non terminés (« Le contrôle n'a pas encore démarré ») et pour les événements en cours, même au-delà de l'heure de fin.

## Conséquences

- Si l'organisateur oublie de démarrer le contrôle, toutes les entrées sont refusées. L'écran du contrôleur l'annonce avant le scan.
- S'il oublie de l'arrêter, le contrôle reste ouvert. Le tableau de bord le montre (« En direct »).
- Les colonnes `scan_opens_before` et `scan_closes_after` ne sont plus lues. Pour les anciennes versions de l'application, `my_scan_posts` continue de renvoyer des heures.
- La règle « au plus une validation acceptée par ticket, jamais hors ligne » est inchangée.
