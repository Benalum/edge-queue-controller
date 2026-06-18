#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gq-ct202-startup-boot-guard-no-autostart-no-enable-regression"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gp-ct202-systemd-manual-start-loopback-smoke-then-stop-no-enable.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gp-smoke.out
echo "PASS: previous Phase 14J-GP smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GQ_CT202_STARTUP_BOOT_GUARD_NO_AUTOSTART_NO_ENABLE_REGRESSION"
require_fixed "PHASE_14J_GQ_RESULT=ct202_startup_boot_guard_no_autostart_no_enable_regression_passed"
require_fixed "APPROVE_PHASE_14J_GQ_CT202_STARTUP_BOOT_GUARD_NO_AUTOSTART_NO_ENABLE_REGRESSION"
require_fixed "PHASE_14J_GQ_CT_ID=202"
require_fixed "PHASE_14J_GQ_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GQ_STATUS=running"
require_fixed "PHASE_14J_GQ_UNIT_PATH=/etc/systemd/system/edge-queue-controller.service"
require_fixed "PHASE_14J_GQ_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "CT202 Proxmox onboot/autostart was off or absent/default-no"
require_fixed "CT202 unit file was present"
require_fixed "SQLite quick_check passed"
require_fixed "unit LoadState was loaded"
require_fixed "unit file state was disabled"
require_fixed "unit active state was inactive"
require_fixed "unit FragmentPath was /etc/systemd/system/edge-queue-controller.service"
require_fixed "jobs row count was 0"
require_fixed "workers row count was 0"
require_fixed "user_sessions row count was 0"
require_fixed "router_logs row count was 0"
require_fixed "edge controller Uvicorn process was absent"
require_fixed "controller runtime port listeners were absent on 7070, 17070, 17071, and 17072"
require_fixed "systemctl start was not performed"
require_fixed "systemctl enable was not performed"
require_fixed "systemctl daemon-reload was not performed"
require_fixed "pct onboot mutation was not performed"
require_fixed "controller runtime activation was not performed"
require_fixed "CT202 service unit exists, but it remains disabled and inactive"
require_fixed "CT202 is not configured to autostart as a controller runtime"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no pct set"
require_fixed "no reboot"
require_fixed "no daemon-reload in GQ"
require_fixed "no systemctl start"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_gr_ct202_readiness_summary_and_cutover_blocker_review_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
