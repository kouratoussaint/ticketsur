# ADR 0055 — Cas de notification P3 à P11

- Statut : acceptée
- Date : 23 novembre 2026
- Décideur : Toussaint (23/11, 17 h 41 : « Liste P1 à P10 » et « Prévenir par défaut (P11) » ; P1 et P2 faits par l'ADR 0054)

## Décisions

| # | Cas | Destinataire | Page |
|---|---|---|---|
| P3 | Ticket annulé par la structure | Détenteur (« Mes tickets »), dans sa langue | Mes tickets |
| P4 | Affectation à un événement (avec la porte) | Contrôleur ou gestionnaire affecté (pas soi-même, pas une copie d'événement) | Mes postes |
| P5 | Nouveau membre (invitation acceptée, attribution) | Propriétaire | Équipe |
| P6 | Événement retiré du catalogue ou remis ; structure suspendue ou réactivée | Propriétaire, toujours, avec le motif | Fiche de l'événement ; Profil |
| P7 | 80 % des tickets permis par le pack (par événement, ou par période) | Propriétaire, une fois par événement ou par période | Mon pack |
| P8 | Nouvelle demande de support, nouvelle réponse d'un utilisateur | Administrateurs ayant la permission « support » (super, support) | Console › Support |
| P9 | Paiement déclaré à valider | Administrateurs « facturation » (super, finance) | Console › Encaisser |
| P10 | Nouveau signalement | Administrateurs « catalogue » (super, modération) | Console › Signalements |
| P11 | « Prévenir la personne » activé par défaut dans la console | Réglage `notify_users` = vrai | — |

- P3 est différé à la fin de la transaction ; il ne part pas pour une annulation faite par la console (qui a son propre message et respecte « Prévenir »), ni quand l'événement est annulé (message de l'ADR 0054).
- Les messages d'un même sujet se remplacent dans la barre (étiquettes `tkt-`, `asg-`, `mbr-`, `blk-`, `org-`, `quota-`, `sup-`, `pay-`, `rep-`).
- P7 couvre les deux limites de tickets (par événement, par période) ; les autres limites du pack bloquent toujours avec la feuille « Limite atteinte ».
- Migration 6600 ; nouvelles pages ouvrables depuis une notification : `/equipe`, `/evenements/<id>`, `/console/support/<id>`, `/console/signalements`, `/console/encaisser/demande/<id>`.
