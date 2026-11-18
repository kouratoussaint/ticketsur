#!/usr/bin/env bash
# =============================================================================
# TicketSûr — Bout en bout « utilisateur connecté » sur un projet Supabase
# Crée un compte jetable (adresse e2e-…@example.com, mot de passe aléatoire
# jamais affiché), se connecte avec un VRAI jeton de session et vérifie :
#   * la politique de mot de passe (≥ 10 caractères) et l'erreur générique ;
#   * qu'un compte sans organisation ne voit ni ne modifie rien (RLS réelle) ;
#   * que validate_scan répond « unauthorized » et que l'émission est refusée.
# Prérequis : « Confirm email » désactivé (staging). Les comptes e2e-… sont
# supprimés par le workflow staging-tests (accès SQL).
# Usage : SUPABASE_URL=… SUPABASE_PUBLISHABLE_KEY=sb_publishable_… bash scripts/e2e-auth-api.sh
# =============================================================================
set -uo pipefail

U="${SUPABASE_URL:?SUPABASE_URL requis}"
K="${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY requis}"
case "$K" in sb_secret_*) echo "Refus : clé secrète." >&2; exit 2;; esac
EMAIL="e2e-$(date +%s)-$RANDOM@example.com"
PASSWORD="$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)"
ZERO=00000000-0000-4000-8000-000000000001
ok=0; ko=0
pass() { echo "OK    $1"; ok=$((ok + 1)); }
fail() { echo "ÉCHEC $1"; ko=$((ko + 1)); }
json() { python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1') if isinstance(d, dict) else '')" 2>/dev/null; }
req() { # méthode chemin [données] → corps dans /tmp/e2e.body, code HTTP en sortie
  local m="$1" p="$2" d="${3:-}"
  local args=(-sS -m 20 -o /tmp/e2e.body -w "%{http_code}" -X "$m" "$U$p" -H "apikey: $K" -H "Content-Type: application/json")
  [ -n "${TOKEN:-}" ] && args+=(-H "Authorization: Bearer $TOKEN")
  [ -n "$d" ] && args+=(-d "$d")
  curl "${args[@]}"
}

echo "Compte jetable : $EMAIL"

code=$(req POST /auth/v1/signup "{\"email\":\"$EMAIL\",\"password\":\"court-9ch\"}")
[[ "$code" =~ ^(400|422)$ ]] && [ "$(json error_code < /tmp/e2e.body)" = weak_password ] \
  && pass "mot de passe de 9 caractères refusé (weak_password)" \
  || fail "mot de passe court accepté ou erreur inattendue (HTTP $code)"

code=$(req POST /auth/v1/signup "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(json access_token < /tmp/e2e.body)
[ "$code" = 200 ] && [ -n "$TOKEN" ] && [ "$TOKEN" != None ] \
  && pass "inscription confirmée automatiquement (staging)" \
  || { fail "inscription sans session (HTTP $code) : « Confirm email » activé ?"; TOKEN=""; }

unset TOKEN
code=$(req POST "/auth/v1/token?grant_type=password" "{\"email\":\"$EMAIL\",\"password\":\"mauvais-mot-de-passe\"}")
[ "$code" = 400 ] && [ "$(json error_code < /tmp/e2e.body)" = invalid_credentials ] \
  && pass "mauvais mot de passe → 400 invalid_credentials (code traduit par l'app)" \
  || fail "mauvais mot de passe : HTTP $code, code $(json error_code < /tmp/e2e.body)"

code=$(req POST "/auth/v1/token?grant_type=password" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(json access_token < /tmp/e2e.body)
[ "$code" = 200 ] && [ -n "$TOKEN" ] && [ "$TOKEN" != None ] && pass "connexion par mot de passe" \
  || { fail "connexion impossible (HTTP $code)"; TOKEN=""; }

if [ -n "$TOKEN" ]; then
  for t in organizations events tickets scan_attempts audit_logs; do
    code=$(req GET "/rest/v1/$t?select=id")
    [ "$code" = 200 ] && [ "$(tr -d ' \n' < /tmp/e2e.body)" = "[]" ] \
      && pass "connecté sans organisation : $t vide (RLS)" || fail "$t : HTTP $code $(head -c 80 /tmp/e2e.body)"
  done
  code=$(req POST /rest/v1/tickets '{"status":"issued"}')
  [[ "$code" =~ ^(401|403)$ ]] && pass "écriture directe dans tickets refusée ($code)" || fail "écriture tickets : HTTP $code"
  code=$(req POST /rest/v1/rpc/validate_scan "{\"p_request_id\":\"$(python3 -c 'import uuid;print(uuid.uuid4())')\",\"p_event_id\":\"$ZERO\",\"p_checkpoint_id\":\"$ZERO\",\"p_qr_token\":\"TS1.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}")
  [ "$code" = 200 ] && [ "$(json result < /tmp/e2e.body)" = unauthorized ] \
    && pass "validate_scan sans affectation → unauthorized" || fail "validate_scan : HTTP $code $(head -c 120 /tmp/e2e.body)"
  code=$(req POST /rest/v1/rpc/issue_tickets "{\"p_event_id\":\"$ZERO\",\"p_category_id\":\"$ZERO\",\"p_quantity\":1}")
  [[ "$code" =~ ^(401|403)$ ]] && pass "issue_tickets sans droits refusé ($code)" || fail "issue_tickets : HTTP $code"
  code=$(req POST /auth/v1/logout)
  [ "$code" = 204 ] && pass "déconnexion (session révoquée côté serveur)" || fail "déconnexion : HTTP $code"
fi

rm -f /tmp/e2e.body
echo "== $ok OK, $ko échec(s)"
[ "$ko" -eq 0 ]
