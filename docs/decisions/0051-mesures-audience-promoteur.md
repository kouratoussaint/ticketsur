# ADR 0051 — Mesures d'audience pour le promoteur

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Enchaîne », 22/11 à 15 h 49 ; lot 4-12, PR C, doc `claude/lot-4-12.md`)

## Décisions

1. **Vues de la fiche publique** d'un événement : un compteur par événement et par jour (heure UTC, celle du Burkina Faso), sans compte, sans adresse IP, sans identifiant d'appareil. L'app envoie une vue par appareil, par événement et par jour (liste du jour gardée dans les préférences, 200 événements au plus) ; un échec est ignoré et la vue sera envoyée à la prochaine ouverture. Le serveur ignore sans erreur un événement qui n'est pas au catalogue. Le chiffre est **indicatif** : rien n'empêche un appel répété, faute d'identifier l'appareil, ce que l'on refuse volontairement.
2. **Fiche de l'événement (propriétaire, gestionnaire)**, hors brouillon : « 124 sur 7 jours · 380 au total » et barres des 30 derniers jours ; pour un événement privé, mention qu'aucune vue n'est comptée.
3. **Abonnés de la structure** (ADR 0047) : ligne « Abonnés de la structure » du Profil (propriétaire, gestionnaire) avec « 12 abonnés · +3 sur 30 jours » ; feuille avec le nombre, les arrivées par jour sur 30 jours (abonnés encore abonnés : un désabonnement efface la ligne) et « Voir la page publique ».
4. Migration 6100 : table `event_page_views` (fermée à l'API), `record_event_view` (visiteurs compris), `event_page_views`, `organization_followers_stats` (propriétaire et gestionnaire seulement).

## Écarts au doc du lot

- Les vues ne sont pas reprises dans le bilan d'après-événement ni les abonnés sur l'Accueil : la fiche de l'événement et le Profil suffisent pour une première version ; à ajouter si Toussaint le demande.

## Conséquences

- Aucun coût ni compte externe ; aucune donnée personnelle nouvelle.
