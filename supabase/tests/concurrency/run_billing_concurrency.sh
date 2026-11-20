#!/usr/bin/env bash
# =============================================================================
# Tikéo — Quotas des packs sous appels concurrents (ADR 0027)
#   BIL-01 : quota de 5 tickets sur la période, 10 émissions unitaires
#            simultanées réparties sur DEUX événements → exactement 5 tickets
#   BIL-02 : 1 structure de plus permise, 6 créations simultanées
#                                                    → exactement 1 structure
# Les quotas sont comptés sous un verrou par compte : deux événements (ou deux
# structures) distincts ne se dépassent pas mutuellement.
# Usage : run_billing_concurrency.sh <nom_base>
# =============================================================================
set -euo pipefail

DB="${1:?nom de base requis}"
OWNER="aaaaaaaa-3601-0000-0000-000000000001"
ORG="aaaaaaaa-3601-0000-0000-0000000000f1"
EV1="aaaaaaaa-3601-0000-0000-0000000000e1"
EV2="aaaaaaaa-3601-0000-0000-0000000000e2"
CAT1="aaaaaaaa-3601-0000-0000-0000000000c1"
CAT2="aaaaaaaa-3601-0000-0000-0000000000c2"
PACK="aaaaaaaa-3601-0000-0000-0000000000a1"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

q() { psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" -c "$1"; }
fail() { echo "ÉCHEC  $*" >&2; exit 1; }

q "insert into auth.users (id, email) values ('$OWNER', 'quota.concurrence@test.local');
   insert into public.organizations (id, name, slug, owner_id)
   values ('$ORG', 'Quotas concurrents', 'quotas-concurrents', '$OWNER');
   insert into public.organization_members (organization_id, user_id, role, active)
   values ('$ORG', '$OWNER', 'owner', true);
   insert into public.events (id, organization_id, title, starts_at, ends_at, status) values
     ('$EV1', '$ORG', 'Quota 1', now() + interval '1 day', now() + interval '1 day 3 hours', 'published'),
     ('$EV2', '$ORG', 'Quota 2', now() + interval '2 days', now() + interval '2 days 3 hours', 'published');
   insert into public.ticket_categories (id, event_id, name) values
     ('$CAT1', '$EV1', 'Standard'), ('$CAT2', '$EV2', 'Standard');
   insert into public.billing_packs (id, name, system, status, durations)
   values ('$PACK', 'Quota 5', 'flat', 'published', '{\"month\": 1000}');
   insert into public.billing_pack_options (pack_id, option_key, included) values
     ('$PACK', 'tickets_per_period', 5), ('$PACK', 'structures', 2);
   insert into public.billing_subscriptions (account_id, pack_id, duration, snapshot, starts_at, ends_at)
   values ('$OWNER', '$PACK', 'month', private.billing_pack_snapshot('$PACK'),
           now() - interval '1 day', now() + interval '1 month');" >/dev/null

# Lance chaque ligne de $2 (une instruction SQL) dans une connexion distincte,
# toutes libérées ensemble par une barrière (verrou consultatif).
storm() {
  local label="$1" spec="$2" lock_key=$((RANDOM + 90000)) i=0
  local fifo="$WORK/holder.$lock_key"
  mkfifo "$fifo"
  ( psql -X -q -At -d "$DB" <<SQL
select pg_advisory_lock($lock_key);
\! cat "$fifo" >/dev/null
select pg_advisory_unlock($lock_key);
SQL
  ) >/dev/null &
  sleep 0.5
  while read -r stmt; do
    i=$((i + 1))
    ( psql -X -q -At -v ON_ERROR_STOP=1 -d "$DB" >"$WORK/$label.$i.out" 2>"$WORK/$label.$i.err" <<SQL
select pg_advisory_lock_shared($lock_key);
set role authenticated;
select test.login('$OWNER');
$stmt
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

: >"$WORK/bil01.spec"
for n in $(seq 1 10); do
  if [ $((n % 2)) = 0 ]; then ev="$EV1" cat="$CAT1"; else ev="$EV2" cat="$CAT2"; fi
  echo "select count(*) from public.issue_tickets('$ev', '$cat', 1);" >>"$WORK/bil01.spec"
done
storm bil01 "$WORK/bil01.spec" || true
issued=$(q "select count(*) from public.tickets where event_id in ('$EV1', '$EV2')")
ok=$(grep -l '^1$' "$WORK"/bil01.*.out 2>/dev/null | wc -l)
refused=$(grep -l 'billing_limit_tickets_per_period' "$WORK"/bil01.*.err 2>/dev/null | wc -l)
[ "$issued" = 5 ] && [ "$ok" = 5 ] && [ "$refused" = 5 ] \
  || fail "BIL-01 : $issued tickets, $ok acceptées, $refused refus (attendu 5, 5, 5)"
echo "OK    BIL-01 10 émissions simultanées sur 2 événements, quota 5 → exactement 5 tickets"

: >"$WORK/bil02.spec"
for n in $(seq 1 6); do
  echo "select 'cree' from public.create_organization('Structure concurrente $n');" >>"$WORK/bil02.spec"
done
storm bil02 "$WORK/bil02.spec" || true
orgs=$(q "select count(*) from public.organizations where owner_id = '$OWNER'")
refused=$(grep -l 'billing_limit_structures' "$WORK"/bil02.*.err 2>/dev/null | wc -l)
[ "$orgs" = 2 ] && [ "$refused" = 5 ] \
  || fail "BIL-02 : $orgs structures, $refused refus (attendu 2, 5)"
echo "OK    BIL-02 6 créations simultanées, 1 structure permise de plus → exactement 1"
