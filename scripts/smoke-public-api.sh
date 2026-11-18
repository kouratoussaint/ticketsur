#!/usr/bin/env bash
# =============================================================================
# TicketSûr — Contrôle « boîte noire » d'un projet Supabase déployé
# Joue le rôle d'un visiteur anonyme muni de la seule clé publishable (publique,
# présente dans l'APK) et vérifie qu'il ne peut RIEN lire ni écrire.
# Usage : SUPABASE_URL=https://<ref>.supabase.co SUPABASE_PUBLISHABLE_KEY=sb_publishable_… \
#         bash scripts/smoke-public-api.sh
# Aucune donnée n'est créée ni modifiée.
# =============================================================================
set -uo pipefail

U="${SUPABASE_URL:?SUPABASE_URL requis}"
K="${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY requis}"
case "$K" in sb_secret_*) echo "Refus : une clé secrète n'a rien à faire ici." >&2; exit 2;; esac
H=(-H "apikey: $K" -H "Content-Type: application/json")
ZERO=00000000-0000-4000-8000-000000000001
ok=0; ko=0

chk() {
  local label="$1" expect="$2"; shift 2
  local code
  code=$(curl -sS -m 15 -o /dev/null -w "%{http_code}" "$@")
  if [[ "$code" =~ ^($expect)$ ]]; then echo "OK    $label ($code)"; ok=$((ok + 1))
  else echo "ÉCHEC $label (HTTP $code, attendu $expect)"; ko=$((ko + 1)); fi
}

for t in profiles organizations organization_members events ticket_categories checkpoints \
         event_assignments tickets scan_requests scan_attempts audit_logs; do
  chk "lecture anonyme de $t refusée" "401|403" "${H[@]}" "$U/rest/v1/$t?select=*&limit=1"
done
chk "écriture anonyme dans tickets refusée" "401|403" -X POST "${H[@]}" "$U/rest/v1/tickets" -d '{"status":"issued"}'
chk "validate_scan refusé sans session" "401|403" -X POST "${H[@]}" "$U/rest/v1/rpc/validate_scan" \
  -d "{\"p_request_id\":\"$ZERO\",\"p_event_id\":\"$ZERO\",\"p_checkpoint_id\":\"$ZERO\",\"p_qr_token\":\"TS1.x\"}"
chk "issue_tickets refusé sans session" "401|403" -X POST "${H[@]}" "$U/rest/v1/rpc/issue_tickets" \
  -d "{\"p_event_id\":\"$ZERO\",\"p_category_id\":\"$ZERO\",\"p_quantity\":1}"
chk "revoke_ticket refusé sans session" "401|403" -X POST "${H[@]}" "$U/rest/v1/rpc/revoke_ticket" -d "{\"p_ticket_id\":\"$ZERO\"}"
chk "schéma private non exposé" "406" "${H[@]}" -H "Accept-Profile: private" "$U/rest/v1/ticket_secrets?select=*"
chk "fonctions internes non appelables" "404" -X POST "${H[@]}" "$U/rest/v1/rpc/vault_secret" -d '{"p_name":"x"}'
chk "service Auth disponible" "200" -H "apikey: $K" "$U/auth/v1/health"

echo "== $ok OK, $ko échec(s)"
[ "$ko" -eq 0 ]
