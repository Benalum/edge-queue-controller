#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gh-ct202-fresh-sqlite-db-created-default-off-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gh-r0-ct202-fresh-sqlite-bootstrap-plan-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gh-r0-smoke.out
echo "PASS: previous Phase 14J-GH-R0 smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GH_CT202_FRESH_SQLITE_DB_CREATED_DEFAULT_OFF_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GH_RESULT=ct202_fresh_sqlite_db_created_default_off_no_runtime_activation"
require_fixed "APPROVE_PHASE_14J_GH_CREATE_CT202_FRESH_SQLITE_DB_DEFAULT_OFF"
require_fixed "PHASE_14J_GH_CT_ID=202"
require_fixed "PHASE_14J_GH_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GH_STATUS=running"
require_fixed "PHASE_14J_GH_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "PHASE_14J_GH_BOOTSTRAP_FUNCTION=init_db"
require_fixed "SQLite quick_check passed"
require_fixed "DB mode is 640"
require_fixed "table count was 11"
require_fixed "index count was 16"
require_fixed "PHASE_14J_GH_SCHEMA_GAP_NOTE=fresh_db_valid_but_auth_user_tables_not_observed"
require_fixed "auth/user/session schema bootstrap"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no fresh DB creation rerun in record phase"
require_fixed "no controller runtime activation"
require_fixed "no systemd service creation"
require_fixed "no systemd start"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no data import"
require_fixed "no live laptop DB mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gi_ct202_auth_schema_bootstrap_gap_inspection_no_runtime_activation"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
