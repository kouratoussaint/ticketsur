# ADR 0004 — Aucune acceptation hors ligne au MVP

- **Statut** : accepté (repris du cahier des charges)
- **Date** : 2026-11-18

## Décision

Sans réponse serveur, l'application **ne montre jamais** « entrée autorisée ». Hors connexion, timeout ou erreur serveur : écran orange « État à confirmer » ou « Vérification impossible ».

Le téléphone garde une **file d'interface** des requêtes en vol (`request_id` stable) et la rejoue à la reconnexion. Le serveur renvoie alors exactement le verdict déjà rendu, s'il existe.

## Pourquoi

Avec plusieurs portes, deux téléphones hors ligne accepteraient chacun la même copie d'un QR. Le mode hors ligne coordonné fera l'objet d'une étude dédiée (post-MVP).

## Conséquence terrain

Le runbook prévoit un réseau de secours (second opérateur, point d'accès dédié) et une procédure manuelle quand le réseau tombe.
