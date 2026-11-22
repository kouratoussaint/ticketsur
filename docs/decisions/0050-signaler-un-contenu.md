# ADR 0050 — Signaler un contenu

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (« Enchaîne », 22/11 à 15 h 49 ; lot 4-12, PR B, doc `claude/lot-4-12.md`)

## Contexte

Le catalogue public est ouvert à tous les promoteurs. La console pouvait déjà retirer un événement ou suspendre une structure, mais seulement si l'équipe trouvait le problème elle-même.

## Décisions

1. **Signaler** depuis la fiche publique d'un événement (« Signaler cet événement ») ou la page d'une structure (« Signaler cette structure »), en bas de page, avec un compte connecté (sans compte : connexion, puis retour sur la fiche). Motif obligatoire parmi 5 : informations trompeuses, arnaque ou faux événement, contenu choquant ou haineux, doublon, autre raison ; commentaire facultatif de 300 caractères.
2. Seul un événement visible au catalogue ou une structure active peut être signalé. Un compte n'a qu'un signalement ouvert par contenu (le second répond « déjà signalé » sans rien ajouter) et 10 signalements par jour au plus.
3. **Console « Signalements »** (permission `catalog` : rôles super et modération) : signalements regroupés par contenu, les plus signalés d'abord, avec motifs comptés et les 5 derniers commentaires ; « À traiter » et « Traités ». Actions, motif obligatoire : « Retirer du catalogue » (événement) ou « Suspendre la structure » (mêmes fonctions et même journal que les actions existantes), « Classer sans suite ». Pastille du nombre à traiter sur la tuile de la console.
4. **Données** : table `content_reports`, fermée à l'API. La structure signalée ne voit ni les signalements, ni qui les a faits, ni leur traitement (le journal `admin.reports_actioned|dismissed` n'a pas de structure, seulement le nombre de signalements ; motif dans le journal des administrateurs). Le commentaire n'est jamais copié dans `audit_logs` (règle 9) ; l'aide du champ demande de ne pas y écrire de numéro ni d'adresse.

## Conséquences

- Migration 6000 : `content_reports`, `report_content`, `admin_content_reports`, `admin_resolve_reports`.
- Aucun coût ni compte externe. Le signaleur n'est pas prévenu du traitement (possible plus tard).
