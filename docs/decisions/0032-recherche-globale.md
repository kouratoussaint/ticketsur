# ADR 0032 — Recherche globale du promoteur

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-6, recherche globale)
- Référence : doc du projet `claude/recommandations-tikeo.md`, lot 4-6 sans coût

## Contexte

Le jour J, un promoteur doit retrouver vite un événement ou le ticket d'une personne (« Aïcha au téléphone, elle n'a plus son ticket ») sans ouvrir chaque événement.

## Décisions

1. **Une fonction serveur** `promoter_search(organisation, texte, limite)` (migration 4400) : réservée au propriétaire et aux gestionnaires de la structure (`forbidden` sinon) ; texte de 2 à 60 caractères (`search_query_invalid` sinon) ; limite de 1 à 50 (20 par défaut).
2. **Événements** trouvés par titre, salle ou ville, sans tenir compte des accents ni des majuscules ; ceux qui commencent par le texte d'abord, puis les plus récents.
3. **Tickets** de tous les événements de la structure trouvés par **référence** (la référence exacte d'abord), **nom du titulaire** (sans accents) ou **téléphone** (à partir de 4 chiffres, espaces et `+` ignorés). Le jeton QR n'est jamais renvoyé ni cherché.
4. **Rien n'est journalisé** : le texte cherché peut contenir un nom ou un téléphone, il ne va ni dans `audit_logs` ni dans les journaux de l'app.
5. **Écran Recherche** (`/recherche`), ouvert par la loupe de l'en-tête de l'Accueil (propriétaire et gestionnaires seulement) : recherche après 300 ms sans frappe, sections Événements et Tickets avec compteurs ; un appui ouvre la fiche de l'événement ou du ticket.

## Conséquences

- Aucun coût ni compte externe.
- Les contrôleurs ne voient pas la loupe : leur accès reste limité à l'événement contrôlé.
