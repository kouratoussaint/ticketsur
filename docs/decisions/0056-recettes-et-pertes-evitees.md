# ADR 0056 — Recettes probables et pertes évitées au tableau de bord

- Statut : acceptée
- Date : 27 novembre 2026
- Décideur : Toussaint (27/11, 9 h 53 : « Recettes probables, calculées sur le nombre d'entrées validées et le coût de chaque type de ticket » ; « Perte probable évitée, calculée sur le nombre d'entrées refusées et le coût de chaque type de ticket refusé »)

## Contexte

Tikéo ne vend pas les tickets : la structure les vend elle-même. Le seul prix connu est le **prix indicatif** de chaque catégorie (`ticket_categories.indicative_price`, en FCFA, facultatif). Le tableau de bord (en direct et bilan) ne montrait que des nombres.

## Décisions

- `event_dashboard` et `closed_event_dashboard` renvoient une section `money` (migration 6700, `private.event_money`) ; mêmes droits et même pack (`live_dashboard`) que le reste du tableau.
- **Recettes probables** = pour chaque catégorie, tickets **entrés** (au moins une entrée acceptée, non annulés) × prix indicatif. Un pass compte une fois, quel que soit le nombre d'entrées.
- **Pertes probables évitées** = pour chaque catégorie, tickets **refusés à la porte** × prix indicatif. Un ticket refusé plusieurs fois compte une fois. Refus retenus : ticket déjà utilisé, annulé, expiré. Un « déjà utilisé » dans la minute qui suit l'entrée de ce ticket est un double scan, pas une fraude : il ne compte pas.
- Ne comptent pas : les **invitations** (0 FCFA), les catégories **sans prix indicatif** (nombre affiché à part), les **QR inconnus ou d'un autre événement** (aucune catégorie : nombre affiché à part).
- Écran : carte « Recettes et pertes évitées » après la courbe des passages, avec les deux montants, le détail par catégorie et les mentions ; si aucune catégorie payante n'a de prix, un bandeau invite à en ajouter un. La carte n'apparaît pas tant qu'aucun ticket n'est émis.
- Ce sont des **estimations** : la carte le dit. Aucune donnée personnelle n'est ajoutée ; rien n'est écrit dans `audit_logs`.

## Aussi dans ce lot

- **Mon pack** : arrivé sur la page sans écran en dessous (après le démarrage d'un essai ou le retour du paiement), le bouton Retour d'Android ouvre le Profil au lieu de quitter l'app (`BackToFallback`).
