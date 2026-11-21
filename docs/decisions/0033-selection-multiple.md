# ADR 0033 — Sélection multiple (événements, favoris, équipe, console)

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-6, sélection multiple)
- Référence : doc du projet `claude/recommandations-tikeo.md`, section 2.1

## Contexte

La sélection multiple existe pour les tickets depuis le lot 3c. Les promoteurs et l'administrateur doivent aussi traiter plusieurs événements, favoris, membres ou comptes d'un coup.

## Décisions

1. **Même geste partout** : un appui long entre en sélection ; un appui coche ou décoche ; Retour ou la croix quittent la sélection. Barre du haut `SelectionAppBar` (nombre choisi, « Tout sélectionner » sur la liste filtrée) et **barre d'actions en bas** `SelectionActionBar` (icône et libellé court). Composants communs dans `lib/design_system/components/selection.dart`.
2. **Pas de nouvelle fonction serveur** : chaque élément passe par la fonction existante, l'un après l'autre (`runBulk`, `lib/core/bulk.dart`). Le serveur vérifie les droits et journalise chaque élément comme pour une action unique. Un échec n'arrête pas les suivants, sauf réseau coupé ou limite du pack atteinte. Le message final dit combien ont abouti.
3. **Éléments laissés de côté avant l'envoi** quand l'action ne les concerne pas (déjà publics, pas terminés pour l'archivage…) ; la confirmation le dit.
4. **Événements** (propriétaire et gestionnaires) : rendre publics, rendre privés, dupliquer (10 au plus ; copie en brouillon une semaine plus tard, même jour et même heure, avec catégories, portes et équipe), archiver (clôturés ou annulés seulement, confirmation en rouge : définitif).
5. **Favoris** : retirer plusieurs favoris, avec « Annuler » dans le message (rien ne part au serveur).

## Conséquences

- Aucun coût ni compte externe, aucune migration.
- Une série longue fait autant d'appels que d'éléments (au plus quelques dizaines dans l'usage prévu).
