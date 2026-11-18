# ADR 0002 — Validation des scans par RPC PostgreSQL directe

- **Statut** : proposé (Phase 0) — prototype vert sur PostgreSQL 16
- **Date** : 2026-11-18

## Contexte

Le verdict d'un scan est la donnée la plus sensible du produit. Il doit être rendu en moins de 2 s (P95 visé) et rester exact sous concurrence. Deux options : une Edge Function qui appelle la base, ou une fonction PostgreSQL appelée directement par l'API (RPC PostgREST).

## Décision

Le mobile appelle `POST /rest/v1/rpc/validate_scan` (via `supabase.rpc`). La fonction `public.validate_scan` fait tout dans **une seule transaction** :

1. identité (`auth.uid()`) et idempotence (`scan_requests`, unique `(actor_id, request_id)`) ;
2. limitation de débit par contrôleur (120 tentatives par minute) ;
3. compte, appartenance, affectation à l'événement **et** à la porte ;
4. état de l'événement et fenêtre de scan, à l'heure serveur ;
5. HMAC du jeton, recherche du billet, contrôle de l'événement ;
6. `UPDATE … WHERE status = 'issued'` : un seul appel peut réussir ;
7. journal `scan_attempts` + réponse versionnée stockée pour les rejeux.

## Pourquoi pas une Edge Function sur ce chemin

- Un saut réseau et un démarrage à froid de plus sur le chemin le plus sensible à la latence.
- La transaction doit de toute façon vivre dans PostgreSQL ; la fonction n'ajouterait que de la validation de forme, déjà faite en SQL.

Une Edge Function reste pertinente pour les tâches hors chemin critique (génération de PDF en masse, envois, webhooks).

## Conséquences

- Jamais d'appel en `GET` (le jeton finirait dans l'URL et les journaux d'accès).
- La limitation de débit par adresse IP relève de la plateforme (Supabase / pare-feu) ; celle par contrôleur est en SQL.
- Preuve : `supabase/tests/concurrency/run_concurrency.sh` (2 et 50 scans simultanés, 10 rejeux simultanés).
