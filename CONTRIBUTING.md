# Contribuer à TicketSûr

## Branches

- `main` est protégée et toujours déployable. Aucun push direct.
- Branches courtes : `feature/<sujet>`, `fix/<sujet>`, `docs/<sujet>`, `chore/<sujet>`.
- Une PR = une intention, liée à une issue et à ses critères d'acceptation.

## Avant d'ouvrir une PR

```bash
bash scripts/db-test.sh          # base : acceptation, concurrence, volume
# Phase 1+ : cd apps/mobile && flutter analyze && flutter test
```

## Définition de « terminé »

Critères d'acceptation satisfaits · tests ajoutés et verts · états d'erreur et UX couverts · RLS et permissions testées · aucun secret dans les journaux · documentation à jour · PR revue · démonstration sur appareil Android pour les flux critiques.

## Base de données

- Toute évolution passe par une **nouvelle** migration horodatée dans `supabase/migrations/` ; une migration déjà fusionnée n'est jamais modifiée.
- Une migration irréversible (suppression de colonne, réécriture de données) est signalée dans la PR avec sa procédure de retour arrière.

## Commits

Messages en français, à l'impératif : `Ajoute la révocation des billets`, `Corrige le réarmement du scanner`.

## Travail avec Claude

Claude travaille sur des branches et des PR explicites, fournit le diff et les commandes de test, et n'affirme jamais avoir poussé, lancé une CI ou déployé sans preuve d'exécution.
