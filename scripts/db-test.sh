#!/usr/bin/env bash
# =============================================================================
# TicketSûr — Tests base de données (local et CI)
# Recrée une base jetable, applique le shim Supabase, les migrations dans
# l'ordre, les données de test, puis exécute :
#   1. les tests d'acceptation séquentiels (SQL) ;
#   2. les tests de concurrence réels (connexions parallèles) ;
#   3. un test de volume : 10 000 billets, unicité totale (AT-21).
# Prérequis : PostgreSQL 15+ accessible via PGHOST/PGPORT/PGUSER (superutilisateur).
# =============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB="${TICKETSUR_TEST_DB:-ticketsur_test}"
PSQL=(psql -X -q -v ON_ERROR_STOP=1)

echo "== Base jetable : $DB"
"${PSQL[@]}" -d postgres -c "drop database if exists $DB with (force)" >/dev/null
"${PSQL[@]}" -d postgres -c "create database $DB" >/dev/null

echo "== Shim Supabase local"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/shim/00_supabase_local_shim.sql" >/dev/null

echo "== Migrations"
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "   $(basename "$f")"
  "${PSQL[@]}" -d "$DB" -f "$f" >/dev/null
done

echo "== Données de test"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/00_fixtures.sql" >/dev/null

echo "== Tests d'acceptation séquentiels"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/10_scan_acceptance.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des organisations"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/20_organizations.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des événements"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/30_events.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du contenu des événements (photo, ville)"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/35_event_content.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du profil et de la fiche d'organisation"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/36_profile_org.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des catégories et des portes"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/40_categories_checkpoints.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests de l'équipe"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/50_team.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des billets (liste, ré-export)"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/60_tickets.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du contrôleur (postes, historique)"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/70_controller.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du tableau de bord en direct"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/80_dashboard.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des tickets nominatifs"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/90_named_tickets.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du journal des envois"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/95_deliveries.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du rapport d'événement"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/96_report.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests des invitations"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/97_invitations.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests du catalogue public"
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/98_public_catalog.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_console.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_console_accounts.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_support.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_legal.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_bulk_duplicate.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_wallet.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_push.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_door.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_templates.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_entries.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_reminders.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_billing.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_billing_console.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_billing_promoter.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_featured.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_invitation_reveal.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_assign_organization.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_devices.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_promoter_search.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_ticket_batches.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_organization_settings.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_console_pro.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_admin_mfa.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_admin_roles_accounts.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_admin_organizations.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_admin_events_tickets.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_admin_search_messages.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_maintenance_signups_exports.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_closed_organizations.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_public_organization.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_organization_follow.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_member_activity.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_followed_events.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_content_reports.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'
"${PSQL[@]}" -d "$DB" -f "$ROOT/supabase/tests/sql/99_safeupdate.sql" 2>&1 | sed 's/^psql:.*NOTICE:  //' | grep -v '^$'

echo "== Tests de concurrence"
bash "$ROOT/supabase/tests/concurrency/run_concurrency.sh" "$DB"
bash "$ROOT/supabase/tests/concurrency/run_issue_concurrency.sh" "$DB"
bash "$ROOT/supabase/tests/concurrency/run_billing_concurrency.sh" "$DB"

echo "== Volume : 10 000 billets (AT-21)"
start=$(date +%s%N)
"${PSQL[@]}" -d "$DB" -At <<'SQL' | grep -v '^$'
select test.login('11111111-1111-1111-1111-111111111111');
create temp table v as
  select * from public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f5', 5000)
  union all
  select * from public.issue_tickets('aaaaaaaa-0000-0000-0000-0000000000e1', 'aaaaaaaa-0000-0000-0000-0000000000f5', 5000);
select test.check('AT-21 10 000 billets émis', count(*)::text, '10000') from v;
select test.check('AT-21 jetons uniques', count(distinct qr_token)::text, '10000') from v;
select test.check('AT-21 références uniques', count(distinct public_reference)::text, '10000') from v;
select test.check('AT-21 empreintes HMAC uniques', count(distinct s.token_hmac)::text, '10000')
  from v join private.ticket_secrets s on s.ticket_id = v.ticket_id;
SQL
end=$(date +%s%N)
awk -v ns=$((end - start)) 'BEGIN { printf "INFO  émission de 10 000 billets : %.1f s (machine de test, indicatif)\n", ns / 1e9 }'

echo "== Tous les tests base de données sont verts."
