# Moteur de scan — fonctionnement et preuves

## Contrat

`public.validate_scan(p_request_id uuid, p_event_id uuid, p_checkpoint_id uuid, p_qr_token text) → jsonb`

Réponse (version 1), champs absents quand ils ne s'appliquent pas :

```json
{
  "version": 1,
  "request_id": "6dd6ae2c-…",
  "result": "accepted",
  "validation_id": "d9918b77-…",
  "ticket": {"public_reference": "TS-UZEY-Q2HM", "category": "Standard"},
  "first_validated_at": "2026-11-18T13:16:52.472496+00:00",
  "checkpoint_label": "Entrée principale",
  "server_time": "2026-11-18T13:16:52.472496+00:00"
}
```

`result` ∈ `accepted`, `already_used`, `revoked`, `expired`, `not_found`, `wrong_event`, `unauthorized`, `event_inactive`, `rate_limited`, `pending`. Le code `unavailable` est produit **par le mobile** quand le serveur ne répond pas.

## Pourquoi un seul scan peut gagner

1. `UPDATE public.tickets SET status = 'redeemed' … WHERE id = $1 AND status = 'issued'`. Sous READ COMMITTED, deux transactions concurrentes se sérialisent sur le verrou de ligne ; la seconde réévalue le `WHERE` après le commit de la première et ne modifie rien.
2. La seconde relit l'état commité et répond `already_used` avec l'heure de la **première** validation.
3. Filet : index unique partiel `scan_attempts (ticket_id) WHERE outcome = 'accepted'`.

## Idempotence

`INSERT INTO scan_requests … ON CONFLICT (actor_id, request_id) DO NOTHING`. Un rejeu concurrent attend le commit de la requête d'origine, puis lit la réponse stockée : même verdict, même `validation_id`, aucune seconde entrée.

## Ce qui ne consomme pas un billet

Refus d'autorisation, mauvais événement, QR inconnu, événement fermé, limitation de débit, coupure réseau : le billet reste `issued`.

## Preuves automatisées (`bash scripts/db-test.sh`)

| Test | Résultat attendu |
| --- | --- |
| AT-01, AT-02, AT-12, AT-13 | accepté, puis `already_used` avec l'heure initiale ; rejeu identique |
| AT-03 | 2 contrôleurs simultanés → 1 accepté |
| AT-04 | 50 contrôleurs simultanés → 1 accepté, 49 `already_used`, une seule heure initiale |
| SCN-09 | 10 rejeux simultanés du même `request_id` → 1 validation, 10 réponses identiques |
| AT-05 à AT-10 | `not_found`, `wrong_event`, `revoked`, `event_inactive`, `unauthorized` |
| AT-14 | aucune lecture ni émission inter-organisations |
| AT-19 | aucun jeton en clair dans les tables métier |
| AT-21 | 10 000 billets : jetons, références et HMAC tous uniques |
