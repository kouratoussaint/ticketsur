# ADR 0007 — Création d'organisation en libre-service

- **Statut** : accepté le 2026-11-18 (décision du propriétaire du produit)

## Décision

Tout utilisateur connecté dont le profil est actif peut créer une organisation et en devient propriétaire (`public.create_organization`, migration 0500). Il n'y a pas de validation préalable par un superadministrateur.

## Garde-fous

- **5 organisations actives au plus par propriétaire** (code SQL `53400`), contrôle sérialisé par un verrou consultatif par utilisateur : deux créations simultanées ne contournent pas la limite.
- Nom nettoyé (espaces multiples), 2 à 120 caractères ; identifiant d'URL (`slug`) dérivé du nom, sans accents, rendu unique par un suffixe aléatoire.
- Chaque création est inscrite au journal d'audit (`organization.created`).
- L'inscription étant ouverte, la production gardera la confirmation d'adresse e-mail activée ; un CAPTCHA à l'inscription est à prévoir avant le lancement public.

## Côté application

Après la première connexion, tant que l'utilisateur n'appartient à aucune organisation, l'écran « Créer votre organisation » remplace l'espace connecté. L'organisation active est mémorisée sur l'appareil, par utilisateur ; on en change depuis l'Accueil ou le Profil (S05).

## Conséquences

- Les invitations (gestionnaires, contrôleurs) restent le seul moyen de rejoindre l'organisation d'un autre (Phase 2, ORG-02).
- La suppression ou l'archivage d'une organisation sera une action de propriétaire, tracée (à concevoir).
