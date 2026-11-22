# ADR 0045 — Page publique d'une structure et « À propos » en tuile

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (demande du 22/11 à 12 h 00)

## Contexte

Sur la fiche publique d'un événement, la partie « À propos » était du texte posé sur le fond, alors que les autres blocs sont des tuiles blanches. Le bloc « Organisé par » n'était pas touchable : impossible de voir les autres événements de la structure.

## Décisions

1. « À propos » est une tuile (`TikeoCard`), comme les autres blocs.
2. Le bloc « Organisé par » affiche le logo de la structure (déjà renvoyé par le serveur, jusqu'ici inutilisé) et, touché, ouvre la **page publique de la structure** (`/organisateur/:id`, avec ou sans compte) : logo, nom, ville, année d'arrivée sur Tikéo, nombre d'événements à venir et déjà organisés, bouton « Contacter sur WhatsApp » (numéro public), liste des événements à venir.
3. Serveur (migration 5500) : `public_event` renvoie aussi `organization.id` ; `public_organization(id)` (visiteurs et comptes) ne renvoie que des données déjà publiques : nom, ville, logo, numéro WhatsApp public, date de création, événements visibles au catalogue (`private.is_listed`, 50 au plus) et nombre d'événements publics passés. Structure suspendue, fermée ou inconnue : `organization_not_found`. Ni membres, ni chiffres de tickets, ni coordonnées privées.

## Conséquences

- Aucun coût ni compte externe.
- Une APK plus ancienne que la migration n'envoie pas l'identifiant : le bloc n'y est simplement pas touchable.
- D'autres améliorations du même type ont été proposées à Toussaint (lieu vers l'itinéraire, ajout à l'agenda, suivre une structure…), en attente de sa validation.
