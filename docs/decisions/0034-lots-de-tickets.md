# ADR 0034 — Lots de génération des tickets, 1 000 par lot

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (« je veux 1000 par lot, sélectionner tout un lot pour la planche ; les tickets regroupés en lot selon la génération »)

## Contexte

Un promoteur émet ses tickets en plusieurs fois (lot rapide, liste nominative, import). Pour imprimer ou renvoyer « ce qu'il a généré tout à l'heure », il devait cocher les tickets un par un. La limite était de 500 par lot dans l'app.

## Décisions

1. **Un lot par génération** : chaque appel d'émission (`issue_tickets`, `issue_named_tickets`, donc aussi l'import) crée un lot numéroté dans l'événement (1, 2, 3…) ; chaque ticket porte son lot (`tickets.batch_id`). Table `ticket_batches` fermée à l'API (migration 4500).
2. **Tickets existants** regroupés par appel d'origine : même événement, même auteur, même heure d'émission (l'heure de la transaction).
3. **Lecture** : `event_ticket_batches(événement)` (numéro, date, auteur, total, valables, utilisés, annulés, nominatifs, catégories) et `batch_ticket_ids(lot)` (tous les tickets du lot, pour la sélection) ; `event_tickets(..., p_batch_id)` filtre et renvoie `batch_number`. Propriétaire et gestionnaires seulement.
4. **App** : bouton « Lots » dans l'en-tête de l'onglet Tickets ; pour chaque lot : afficher ses tickets, **sélectionner tout le lot** (PDF, planche, annulation), ou **planche A4** directe des tickets valables. Avec un lot affiché, « Tout sélectionner » prend le lot entier, même les tickets pas encore chargés. Le numéro du lot figure sur chaque ligne.
5. **1 000 par lot** : feuille d'émission (raccourcis 500 et 1 000) et émission nominative ou import (serveur : 1 000 lignes au lieu de 500). L'émission anonyme côté serveur garde sa limite de 5 000. Les annulations groupées partent par paquets de 500.
6. Journal : le numéro du lot s'ajoute à `tickets.issued`, sans nom ni téléphone.

## Conséquences

- Aucun coût. Les anciennes APK continuent de fonctionner (paramètres et colonnes ajoutés seulement).
- Une planche de 1 000 tickets demande du temps et de la mémoire au téléphone (environ 334 pages à 3 par feuille).
