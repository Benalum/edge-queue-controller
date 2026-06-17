#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ft-read-only-data-authority-inspection-and-data-container-design-boundary"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- phase/result markers ---"
require_fixed "PHASE_14J_FT_READ_ONLY_DATA_AUTHORITY_INSPECTION_AND_DATA_CONTAINER_DESIGN_BOUNDARY"
require_fixed "PHASE_14J_FT_RESULT=data_authority_inspection_recorded_no_container_creation"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fu_sqlite_backup_restore_and_data_container_design_plan_no_creation"

echo "--- SQLite authority markers ---"
require_fixed "PHASE_14J_FT_SQLITE_AUTHORITY=live_primary_controller_platform_data_authority"
require_fixed 'DB_PATH = Path("edge_queue.sqlite3")'
require_fixed "SQLite table count: 39"
require_fixed "SQLite index count: 18"
require_fixed "app_users"
require_fixed "user_sessions"
require_fixed "user_credit_ledger"
require_fixed "jobs"
require_fixed "job_results"
require_fixed "workers"
require_fixed "worker_events"
require_fixed "study_decks"
require_fixed "study_sessions"
require_fixed "intent_definitions"
require_fixed "router_logs"
require_fixed "web_presence"
require_fixed "power_events"

echo "--- PostgreSQL boundary markers ---"
require_fixed "PHASE_14J_FT_POSTGRES_AUTHORITY=not_proven_authoritative_foundation_or_parked_pending_sudo_read"
require_fixed "PostgreSQL 16 cluster is online"
require_fixed "Noninteractive sudo access to inspect PostgreSQL as postgres was not available"
require_fixed "PostgreSQL must not be deleted, migrated, or treated as the live authority"

echo "--- design boundary markers ---"
require_fixed "do not create containers"
require_fixed "controller DB path configurability"
require_fixed "rollback path that keeps the laptop authoritative"
require_fixed "Recommended sequence"
require_fixed "data container or VM"
require_fixed "controller/queue container"
require_fixed "worker container"

echo "--- hard-denial markers ---"
require_fixed "no container creation"
require_fixed "no data migration"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no worker start"
require_fixed "no production DB/job mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "--- doc secret/raw endpoint guard ---"
if grep -Eq 'eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
