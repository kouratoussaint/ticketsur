# ADR 0009 — Photos de couverture des événements

- Statut : accepté
- Date : 2026-11-19

## Contexte

Un événement doit avoir une photo et une ville pour être publié (lot 1 du
plan d'évolution). Les photos seront aussi montrées au public (page publique
prévue), sur les tickets partagés et à l'écran de contrôle.

## Décision

- Les photos sont stockées dans le bucket Supabase Storage `event-covers`,
  en **lecture publique**, limité à 2 Mo et aux types JPEG, PNG et WebP.
- Chemin imposé : `<organisation>/<événement>/<nom aléatoire>.<ext>`. Les
  politiques RLS de `storage.objects` n'autorisent le dépôt, la lecture via
  l'API et la suppression qu'aux propriétaires et gestionnaires de
  l'organisation (`private.can_manage_event_cover`).
- La photo n'est rattachée à l'événement que par `set_event_cover`, qui
  vérifie le dossier et l'existence de l'objet, et journalise le changement.
- La publication (`set_event_status`) exige une photo et une ville ; un
  événement publié ne peut perdre ni l'une ni l'autre (`event_incomplete`).
- L'application réduit l'image avant l'envoi (1600 px au plus, JPEG qualité
  82, fait par le système) et supprime l'ancien fichier après un changement ;
  un fichier orphelin éventuel est sans conséquence.

## Conséquences

- Une photo de brouillon est techniquement accessible à qui connaît son
  adresse aléatoire : acceptable, les photos sont destinées au public.
- Aucune donnée personnelle ni jeton QR n'est jamais stocké dans ce bucket.
- La modération (retrait d'une image signalée) relèvera de la console
  d'administration (lot 3 et 4).
