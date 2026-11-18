# ADR 0006 — Dépôt GitHub public

- **Statut** : accepté le 2026-11-18 (écart assumé au cahier des charges, qui prévoyait un dépôt privé)
- **Décideur** : propriétaire du produit

## Décision

`kouratoussaint/ticketsur` reste public.

## Conséquences et garde-fous

- **Aucun secret dans le dépôt, son historique, les issues ou les journaux d'Actions.** Le workflow `security` (gitleaks) bloque une PR qui en contiendrait ; un secret poussé par erreur est considéré compromis et **révoqué**, pas seulement supprimé de l'historique.
- **La sécurité ne dépend pas du secret du code** : jetons de 256 bits, clés dans Supabase Vault, autorisations et transaction côté serveur. Publier `validate_scan` n'aide pas à fabriquer un billet.
- **GitHub Actions** : jamais de déclencheur `pull_request_target` ; les PR venant de forks ne reçoivent aucun secret ; les déploiements passent par des environnements protégés (`staging`, `production`) avec approbation.
- **Branche `main` protégée** : PR obligatoire, checks `db-tests` et `security` requis, revue CODEOWNERS sur `supabase/` et `.github/`.
- **Signalement privé des vulnérabilités** activé (Settings → Code security).
- **Marque** : la licence propriétaire (`LICENSE`) reste en vigueur ; public ne veut pas dire libre de réutilisation.
