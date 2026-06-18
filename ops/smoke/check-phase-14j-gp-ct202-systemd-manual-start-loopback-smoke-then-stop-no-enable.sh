#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gp-ct202-systemd-manual-start-loopback-smoke-then-stop-no-enable"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-go-ct202-systemd-unit-static-smoke-disabled-state-regression.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-go-smoke.out
echo "PASS: previous Phase 14J-GO smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GP_CT202_SYSTEMD_MANUAL_START_LOOPBACK_SMOKE_THEN_STOP_NO_ENABLE"
require_fixed "PHASE_14J_GP_RESULT=ct202_systemd_manual_start_loopback_smoke_then_stop_passed_no_enable"
require_fixed "APPROVE_PHASE_14J_GP_CT202_SYSTEMD_MANUAL_START_LOOPBACK_SMOKE_THEN_STOP_NO_ENABLE"
require_fixed "PHASE_14J_GP_CT_ID=202"
require_fixed "PHASE_14J_GP_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GP_STATUS=running"
require_fixed "PHASE_14J_GP_UNIT_PATH=/etc/systemd/system/edge-queue-controller.service"
require_fixed "PHASE_14J_GP_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "unit was disabled before start"
require_fixed "unit was inactive before start"
require_fixed "no controller runtime port listeners existed before start"
require_fixed "systemctl start edge-queue-controller.service was performed"
require_fixed "unit became active during the smoke"
require_fixed "unit remained disabled during the smoke"
require_fixed "/openapi.json on 127.0.0.1:7070 returned HTTP 200"
require_fixed "OpenAPI path count was at least 100"
require_fixed "system/status/health routes were present"
require_fixed "queue/job/worker routes were present"
require_fixed "loopback listener on 7070 was present during the smoke"
require_fixed "systemctl stop edge-queue-controller.service was performed"
require_fixed "unit became inactive after stop"
require_fixed "unit remained disabled after stop"
require_fixed "edge controller Uvicorn process was absent after stop"
require_fixed "controller runtime port listeners were absent after stop on 7070, 17070, 17071, and 17072"
require_fixed "CT202 DB hash stayed unchanged"
require_fixed "jobs row count stayed unchanged"
require_fixed "workers row count stayed unchanged"
require_fixed "user_sessions row count stayed unchanged"
require_fixed "router_logs row count stayed unchanged"
require_fixed "SQLite quick_check passed after stop"
require_fixed "CT202 service unit exists, but it remains disabled and inactive after this phase"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no systemctl enable"
require_fixed "no persistent controller runtime activation"
require_fixed "no persistent Uvicorn process left running"
require_fixed "no public route mutation"
require_fixed "no Cloudflare route mutation"
require_fixed "no laptop controller stop"
require_fixed "no data migration"
require_fixed "no data import"
require_fixed "no live laptop DB mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "no token or password recording"
require_fixed "no public API key recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gq_ct202_startup_boot_guard_no_autostart_no_enable_regression_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
