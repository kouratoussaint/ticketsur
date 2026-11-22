# ADR 0043 — Explorer sans réseau

- Statut : acceptée
- Date : 22 novembre 2026
- Décideur : Toussaint (lot 4-10 de `claude/proposition-suite-sans-paiement.md`, lancé le 22/11)

## Contexte

Sans réseau, l'Explorer n'affichait qu'un message « Pas de connexion ». Les coupures sont fréquentes ; le public doit pouvoir revoir les événements déjà vus.

## Décisions

1. **Gardé sur l'appareil** (`SharedPreferences`, comme « Mes tickets ») : la première page des **4 dernières recherches** abouties et la dernière liste « À la une ». Données publiques seulement (celles de `public_events`), aucune donnée de compte. Les événements terminés sont écartés à la relecture.
2. **Sans réseau** : si la même recherche a déjà abouti sur l'appareil, ses résultats s'affichent avec le bandeau « Hors ligne, mis à jour il y a … » (la durée avance seule). Sinon, le message « Pas de connexion » reste. « Voir plus » est masqué hors ligne.
3. **Retour du réseau, sans nouvelle dépendance** : nouvel essai après 15 s, 30 s, 1 min puis toutes les 2 min, et tout de suite au retour dans l'app ou en tirant la liste. Au premier succès, la liste et « À la une » sont remplacées sans écran de chargement.
4. La fiche d'un événement n'est pas gardée (hors lot).

## Conséquences

- Aucun coût ni compte externe ; pas de plugin de connectivité.
- Le retour du réseau est vu au prochain essai (2 min au plus), pas instantanément.
- À vérifier sur téléphone : ouvrir l'Explorer, couper les données, fermer puis rouvrir l'app (liste et bandeau), remettre les données (mise à jour sans rien toucher).
