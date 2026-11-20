#!/usr/bin/env bash
# =============================================================================
# TicketSûr — Preuve de l'invariant « une seule entrée » sous concurrence réelle
#   AT-03 : 2 contrôleurs, même QR, au même instant      → 1 accepted
#   AT-04 : 50 contrôleurs, même QR, au même instant     → 1 accepted, 49 already_used
#   SCN-09: 10 rejeux simultanés du MÊME request_id      → 1 seule validation, 10 réponses identiques
# Chaque appel est une connexion PostgreSQL distincte, sous le rôle authenticated.
# Une barrière (verrou consultatif) libère toutes les connexions ensemble.
# Usage : run_concurrency.sh <nom_base>   (variables PGHOST/PGPORT/PGUSER lues)
# =============================================================================
set -euo pipefail

DB="${1:?nom de base requis}"
EV_A1="aaaaaaaa-0000-0000-0000-0000000000e1"
CP_MAIN="aaaaaaaa-0000-0000-0000-0000000000c1"
CTRL_A1="11111111-0000-0000-0000-000000000001"
CTRL_A2="11111111-0000-0000-0000-000000000002"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

q() { psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" -c "$1"; }
fail() { echo "ÉCHEC  $*" >&2; exit 1; }

# Lance N appels validate_scan bloqués derrière une barrière, puis les libère.
#   $1 étiquette du billet, $2 fichier de spécification « acteur request_id » par ligne
storm() {
  local label="$1" spec="$2" lock_key=$((RANDOM + 1000)) i=0
  local holder_fifo="$WORK/holder.$lock_key"
  mkfifo "$holder_fifo"
  # Session « portier » : prend le verrou exclusif et attend l'ordre de libération.
  ( psql -X -q -At -d "$DB" <<SQL
select pg_advisory_lock($lock_key);
\! cat "$holder_fifo" >/dev/null
select pg_advisory_unlock($lock_key);
SQL
  ) >/dev/null &
  local holder_pid=$!
  sleep 0.5

  while read -r actor req; do
    i=$((i + 1))
    ( psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" >"$WORK/$label.$i.out" 2>"$WORK/$label.$i.err" <<SQL
select pg_advisory_lock_shared($lock_key);
set role authenticated;
select test.login('$actor');
select public.validate_scan('$req', '$EV_A1', '$CP_MAIN', test.tok('$label'));
SQL
    ) &
  done <"$spec"

  # Attendre que toutes les connexions soient bloquées sur la barrière.
  local waiting=0
  for _ in $(seq 1 100); do
    waiting=$(q "select count(*) from pg_locks where locktype = 'advisory' and objid = $lock_key and not granted")
    [ "$waiting" -ge "$i" ] && break
    sleep 0.1
  done
  [ "$waiting" -ge "$i" ] || fail "$label : seulement $waiting/$i connexions à la barrière"

  echo go >"$holder_fifo"   # libération simultanée
  wait
  cat "$WORK"/"$label".*.err 2>/dev/null | grep -v '^$' && fail "$label : erreurs SQL ci-dessus" || true
}

count_result() { grep -h -o "\"result\": \"$2\"" "$WORK"/"$1".*.out | wc -l | tr -d ' '; }

# --- AT-03 : deux contrôleurs -------------------------------------------------------
printf '%s %s\n%s %s\n' "$CTRL_A1" "$(q 'select gen_random_uuid()')" \
                        "$CTRL_A2" "$(q 'select gen_random_uuid()')" >"$WORK/spec2"
storm a1_010 "$WORK/spec2"
acc=$(count_result a1_010 accepted); used=$(count_result a1_010 already_used)
[ "$acc" = 1 ] && [ "$used" = 1 ] || fail "AT-03 attendu 1 accepted + 1 already_used, obtenu $acc + $used"
echo "OK    AT-03 2 contrôleurs simultanés → 1 accepted, 1 already_used"

# --- AT-04 : cinquante contrôleurs ---------------------------------------------------
: >"$WORK/spec50"
for n in $(seq 1 50); do
  printf '33333333-0000-0000-0000-%012d %s\n' "$n" "$(q 'select gen_random_uuid()')" >>"$WORK/spec50"
done
storm a1_011 "$WORK/spec50"
acc=$(count_result a1_011 accepted); used=$(count_result a1_011 already_used)
[ "$acc" = 1 ] && [ "$used" = 49 ] || fail "AT-04 attendu 1 + 49, obtenu $acc accepted + $used already_used"
db_acc=$(q "select count(*) from public.scan_attempts sa join test.tokens k on k.ticket_id = sa.ticket_id where k.label = 'a1_011' and sa.outcome = 'accepted'")
[ "$db_acc" = 1 ] || fail "AT-04 la base contient $db_acc validations acceptées"
distinct_first=$(grep -h -o '"first_validated_at": "[^"]*"' "$WORK"/a1_011.*.out | sort -u | wc -l | tr -d ' ')
[ "$distinct_first" = 1 ] || fail "AT-04 $distinct_first heures de première validation différentes"
echo "OK    AT-04 50 contrôleurs simultanés → 1 accepted, 49 already_used, 1 seule heure initiale"

# --- SCN-09 : rejeux simultanés du même request_id -----------------------------------
REQ="$(q 'select gen_random_uuid()')"
: >"$WORK/spec_idem"
for _ in $(seq 1 10); do echo "$CTRL_A1 $REQ" >>"$WORK/spec_idem"; done
storm a1_012 "$WORK/spec_idem"
distinct=$(grep -h '"result"' "$WORK"/a1_012.*.out | sort -u | wc -l | tr -d ' ')
acc=$(count_result a1_012 accepted)
[ "$distinct" = 1 ] && [ "$acc" = 10 ] || fail "SCN-09 attendu 10 réponses identiques, obtenu $distinct variantes"
rows=$(q "select count(*) from public.scan_requests where request_id = '$REQ'")
[ "$rows" = 1 ] || fail "SCN-09 $rows lignes scan_requests pour un même request_id"
echo "OK    SCN-09 10 rejeux simultanés du même request_id → 1 validation, 10 réponses identiques"

# --- Invariant global ------------------------------------------------------------------
# Entrée unique : une acceptation au plus ; pass de N entrées : N au plus ;
# pass journalier : une par jour (fuseau de l'événement) au plus (ADR 0024).
dup=$(q "select count(*) from (
  select sa.ticket_id
    from public.scan_attempts sa
    join public.tickets t on t.id = sa.ticket_id
    join public.ticket_categories c on c.id = t.category_id
    join public.events e on e.id = t.event_id
   where sa.outcome = 'accepted'
   group by sa.ticket_id, c.entry_policy, c.max_entries,
            case when c.entry_policy = 'per_day'
                 then (sa.server_time at time zone e.timezone)::date end
  having count(*) > case c.entry_policy when 'limited' then c.max_entries else 1 end) d")
[ "$dup" = 0 ] || fail "Invariant violé : $dup billets acceptés au-delà de leur règle d'entrée"
echo "OK    Invariant : aucun billet accepté au-delà de sa règle d'entrée sur l'ensemble du run"
