# ADR 0049 — Lot 4-12 : suivre, signaler, mesurer

- Statut : acceptée (PR A) ; PR B et C proposées
- Date : 22 novembre 2026
- Décideur : Toussaint (« Après ce lot continue avec le lot suivant », 22/11 à 14 h 03). Lot sans coût défini par Claude dans le doc `claude/lot-4-12.md` du projet ; Toussaint peut en retirer ou réordonner une partie.

## Contexte

Les 11 améliorations du 22/11 (ADR 0045 à 0048) sont faites ; la mise en production attend toujours les comptes. Le lot 4-12 prolonge le suivi des structures (ADR 0047) côté spectateur, ajoute la modération par signalement et donne au promoteur des mesures d'audience, sans coût ni compte externe.

## Décisions (PR A, côté spectateur)

1. **« De vos structures suivies »** dans l'Explorer, sous « À la une » : les 3 prochains événements publics des structures suivies, « Tout voir » vers la liste des structures suivies. Absent sans compte, sans structure suivie, en cas d'échec de lecture, ou pendant une recherche ou un filtre. Migration 5900 : `my_followed_events(limite ≤ 20)`, comptes connectés seulement, mêmes champs de vitrine que `public_events`.
2. **Périodes en un geste** dans l'Explorer : « Aujourd'hui », « Ce week-end », « Cette semaine » sous les types ; un second appui retire la période. C'est le filtre de la feuille des filtres (badge compté), qui reste disponible.
3. **Mon ticket** : pastille « Dans 3 jours », « Demain à 21:00 », « Aujourd'hui à 21:00 », « En cours », « Terminé » (jours comptés dans le fuseau de l'événement, mise à jour chaque minute) ; « Partager l'événement » (même feuille que la fiche publique) pour un événement visible au catalogue et pas terminé.

## Conséquences

- Aucun coût ni compte externe ; aucune donnée personnelle nouvelle.
- La section suivie n'est pas gardée sur l'appareil (pas de lecture hors ligne).
