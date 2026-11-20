# ADR 0024 — Pass à plusieurs entrées

- Statut : acceptée
- Date : 20 novembre 2026
- Décideur : Toussaint (réponse du 20/11 sur le lot 4-4, ADR 0022 point 2)

## Contexte

La règle d'origine (ADR 0014) admet **au plus une validation acceptée par ticket**. Les festivals sur plusieurs jours et les abonnements demandent un ticket qui rouvre la porte. Toussaint a choisi les deux formules, au choix du promoteur, par catégorie.

## Décision

- **Règle d'entrée par catégorie** (`ticket_categories.entry_policy`) :
  - `single` (par défaut) : une seule entrée, comme avant ;
  - `per_day` : une entrée par jour, le jour étant celui du **fuseau de l'événement** ;
  - `limited` : N entrées au total (`max_entries`, de 2 à 100), sur un ou plusieurs jours.
- **Réglage** : `set_category_entry_policy` (propriétaire et gestionnaires), journalisé `category.entries_changed` (règle et nombre, aucune donnée personnelle). **La règle est figée dès qu'un ticket de la catégorie est entré** (`category_has_entries`) ; la duplication d'un événement la recopie.
- **Validation** : toujours **en ligne, atomique, par `validate_scan`** (la saisie manuelle à la porte passe par la même fonction). Contrôle ouvert seulement si l'événement est `in_progress`. Aucune entrée acceptée hors ligne.
  - Un seul `UPDATE` conditionnel par entrée : `entries_used < max_entries` pour un pass limité, « dernière entrée avant aujourd'hui » pour un journalier. Deux scans simultanés ne peuvent donc pas consommer la même entrée.
  - Filet de sécurité en base : l'index unique « une acceptation par ticket » devient « **une acceptation par numéro d'entrée** » (`scan_attempts.entry_number`). Un ticket à entrée unique garde exactement la protection d'avant.
- **États du ticket** :
  - entrée unique : `redeemed` dès l'entrée (inchangé) ;
  - pass limité : `issued` tant qu'il reste des entrées, `redeemed` à la dernière ;
  - pass journalier : `issued` jusqu'à la fin (ou l'annulation).
  - Colonnes : `entries_used`, `first_entry_at` / `first_entry_checkpoint_id`, `last_entry_at` / `last_entry_checkpoint_id`.
- **Titulaire figé** dès la première entrée d'un pass : un pass ne se prête pas d'un jour à l'autre.
- **Réponse de `validate_scan`** : champ facultatif `entries` (`policy`, `used`, `max`) pour un pass ; la version du contrat reste 1 et les anciennes applications l'ignorent. Pour un pass, `already_used` signifie « déjà entré aujourd'hui » (journalier) ou « pass épuisé » (limité), avec l'heure et la porte de la dernière entrée.
- **Tableaux de bord** : « Entrés » compte les **personnes** (tickets entrés au moins une fois, non annulés) ; les tentatives acceptées comptent les **entrées**. L'égalité « émis = entrés + restants + expirés » est conservée. L'application affiche « N entrées au total » quand les deux diffèrent.

## Conséquences

- Exception explicite à la règle 4 des consignes : elle ne vaut que pour les catégories réglées en pass ; toutes les autres gardent une seule entrée.
- L'invariant global des tests de concurrence devient « aucun ticket accepté au-delà de sa règle d'entrée ».
- Pas de coût ni de compte externe.
