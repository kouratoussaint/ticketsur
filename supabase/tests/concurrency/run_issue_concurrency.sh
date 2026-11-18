#!/usr/bin/env bash
# =============================================================================
# TicketSûr — Capacité de l'événement sous émissions concurrentes (EVT-03)
#   CAP-01 : 2 lots simultanés de 6 billets, DEUX catégories différentes,
#            événement de capacité 10            → 1 lot accepté, 1 refusé, 6 billets
#   CAP-02 : 20 émissions unitaires simultanées, capacité restante 4
#                                                 → exactement 4 billets de plus
# Sans le verrou de l'événement, deux catégories distinctes ne se bloquaient
# pas mutuellement et la capacité globale pouvait être dépassée.
# Usage : run_issue_concurrency.sh <nom_base>
# =============================================================================
set -euo pipefail

DB="${1:?nom de base requis}"
OWNER="11111111-1111-1111-1111-111111111111"
ORG="aaaaaaaa-0000-0000-0000-000000000001"
EV="aaaaaaaa-0000-0000-0000-0000000000a7"
CAT1="aaaaaaaa-0000-0000-0000-0000000000b1"
CAT2="aaaaaaaa-0000-0000-0000-0000000000b2"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

q() { psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" -c "$1"; }
fail() { echo "ÉCHEC  $*" >&2; exit 1; }

q "insert into public.events (id, organization_id, title, starts_at, ends_at, status, capacity)
   values ('$EV', '$ORG', 'Capacité 10', now() + interval '1 day', now() + interval '1 day 3 hours', 'published', 10);
   insert into public.ticket_categories (id, event_id, name) values
     ('$CAT1', '$EV', 'Standard'), ('$CAT2', '$EV', 'VIP');" >/dev/null

# Lance chaque ligne de $2 (« catégorie quantité ») dans une connexion distincte,
# toutes libérées ensemble par une barrière (verrou consultatif).
storm() {
  local label="$1" spec="$2" lock_key=$((RANDOM + 50000)) i=0
  local fifo="$WORK/holder.$lock_key"
  mkfifo "$fifo"
  ( psql -X -q -At -d "$DB" <<SQL
select pg_advisory_lock($lock_key);
\! cat "$fifo" >/dev/null
select pg_advisory_unlock($lock_key);
SQL
  ) >/dev/null &
  sleep 0.5
  while read -r cat qty; do
    i=$((i + 1))
    ( psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" >"$WORK/$label.$i.out" 2>"$WORK/$label.$i.err" <<SQL
select pg_advisory_lock_shared($lock_key);
set role authenticated;
select test.login('$OWNER');
select count(*) from public.issue_tickets('$EV', '$cat', $qty);
SQL
    ) &
  done <"$spec"
  local waiting=0
  for _ in $(seq 1 100); do
    waiting=$(q "select count(*) from pg_locks where locktype = 'advisory' and objid = $lock_key and not granted")
    [ "$waiting" -ge "$i" ] && break
    sleep 0.1
  done
  [ "$waiting" -ge "$i" ] || fail "$label : seulement $waiting/$i connexions à la barrière"
  echo go >"$fifo"
  wait
}

issued() { q "select count(*) from public.tickets where event_id = '$EV' and status <> 'revoked'"; }

printf '%s 6\n%s 6\n' "$CAT1" "$CAT2" >"$WORK/cap01.spec"
storm cap01 "$WORK/cap01.spec" || true
ok=$(grep -l '^6$' "$WORK"/cap01.*.out 2>/dev/null | wc -l)
refused=$(grep -l 'event_capacity_exceeded' "$WORK"/cap01.*.err 2>/dev/null | wc -l)
[ "$ok" = 1 ] && [ "$refused" = 1 ] && [ "$(issued)" = 6 ] \
  || fail "CAP-01 : $ok lot(s) accepté(s), $refused refus, $(issued) billets (attendu 1, 1, 6)"
echo "OK    CAP-01 2 lots simultanés sur 2 catégories, capacité 10 → 1 accepté, 1 refusé, 6 billets"

: >"$WORK/cap02.spec"
for n in $(seq 1 20); do
  if [ $((n % 2)) = 0 ]; then echo "$CAT1 1"; else echo "$CAT2 1"; fi >>"$WORK/cap02.spec"
done
storm cap02 "$WORK/cap02.spec" || true
[ "$(issued)" = 10 ] || fail "CAP-02 : $(issued) billets au lieu de 10"
ok=$(grep -l '^1$' "$WORK"/cap02.*.out 2>/dev/null | wc -l)
[ "$ok" = 4 ] || fail "CAP-02 : $ok émissions acceptées au lieu de 4"
echo "OK    CAP-02 20 émissions simultanées, 4 places restantes → exactement 4 billets, capacité 10 respectée"
