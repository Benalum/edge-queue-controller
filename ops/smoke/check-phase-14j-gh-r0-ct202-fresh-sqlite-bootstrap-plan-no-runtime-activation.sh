#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gh-r0-ct202-fresh-sqlite-bootstrap-plan-no-runtime-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gg-ct202-python-venv-dependency-install-default-off-no-runtime-activation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gg-smoke.out
echo "PASS: previous Phase 14J-GG smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GH_R0_CT202_FRESH_SQLITE_BOOTSTRAP_PLAN_NO_RUNTIME_ACTIVATION"
require_fixed "PHASE_14J_GH_R0_RESULT=ct202_fresh_sqlite_bootstrap_plan_recorded_no_apply"
require_fixed "PHASE_14J_GH_R0_CT_ID=202"
require_fixed "PHASE_14J_GH_R0_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GH_R0_STATUS=running"
require_fixed "PHASE_14J_GH_R0_BOOTSTRAP_DECISION=fresh_sqlite_on_ct202_local_disk_first"
require_fixed "/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "EDGE_QUEUE_SQLITE_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "APPROVE_PHASE_14J_GH_CREATE_CT202_FRESH_SQLITE_DB_DEFAULT_OFF"
require_fixed "laptop-local edge_queue.sqlite3 remains live authority"
require_fixed "no fresh DB creation"
require_fixed "no controller runtime activation"
require_fixed "no systemd service creation"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gh_create_ct202_fresh_sqlite_db_default_off_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
