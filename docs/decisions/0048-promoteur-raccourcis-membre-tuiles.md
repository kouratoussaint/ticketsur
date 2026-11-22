# ADR 0048 — Raccourcis de l'Accueil, fiche d'un membre, tuiles blanches partout

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Tout », 22/11 à 12 h 53 ; améliorations n° 9, 10 et 11)

## Décisions

1. **Raccourcis de l'Accueil** : sur la carte de l'événement en tête, « Entrés » ouvre l'onglet Tickets de cet événement filtré sur les tickets utilisés, « Émis » le même onglet sans filtre, « Présence » le tableau de bord. Les tuiles « Événements », « En cours », « À venir », « Brouillons » ouvrent la liste des événements filtrée. Le filtre est posé même si l'onglet est déjà ouvert (demande de filtre `FilterRequestController`) et mémorisé comme un choix manuel.
2. **Fiche d'un membre** (`/equipe/membre/:id`, propriétaire et gestionnaires) : rôle, accès, entrées validées (au total, sur 30 jours, la dernière), nombre d'événements où il a validé, affectations aux événements à venir avec leur porte (appui → fiche de l'événement). « Modifier le rôle ou l'accès » s'y trouve quand c'est permis (mêmes règles qu'avant). Migration 5800 : `member_activity(structure, compte)` ; aucune donnée de spectateur.
3. **Tuiles blanches partout** : après un relevé de tous les écrans de l'audit, les formulaires et textes posés à nu sur le fond sont mis en tuiles : modifier le profil, modifier la structure (fiche et page publique), formulaire d'événement (étapes 1 et 2), nouvelle demande de support, paiement d'un pack (étape 2, bénéficiaire), mentions légales, introduction des modèles de tickets, appareils connectés, listes vides de la console et du journal, « À la une » vide, annonce, encaissement, pack, édition des mentions.

## Conséquences

- Aucun coût ni compte externe.
- Le test `95_deliveries.sql` ne dépend plus d'une référence de ticket tirée au hasard (échec ponctuel sur `main` après la PR #98, vert à la relance).
