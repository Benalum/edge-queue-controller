#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gr-ct202-readiness-summary-and-cutover-blocker-review"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gq-ct202-startup-boot-guard-no-autostart-no-enable-regression.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gq-smoke.out
echo "PASS: previous Phase 14J-GQ smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GR_CT202_READINESS_SUMMARY_AND_CUTOVER_BLOCKER_REVIEW"
require_fixed "PHASE_14J_GR_RESULT=ct202_readiness_summary_and_cutover_blocker_review_recorded"
require_fixed "APPROVE_PHASE_14J_GR_CT202_READINESS_SUMMARY_AND_CUTOVER_BLOCKER_REVIEW"
require_fixed "PHASE_14J_GR_REPO_HEAD_BEFORE=a51e57d"
require_fixed "PHASE_14J_GR_CT_ID=202"
require_fixed "PHASE_14J_GR_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GR_STATUS=running"
require_fixed "PHASE_14J_GR_UNIT_PATH=/etc/systemd/system/edge-queue-controller.service"
require_fixed "PHASE_14J_GR_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "CT202 Proxmox onboot/autostart was off"
require_fixed "CT202 table count was 25"
require_fixed "jobs row count was 0"
require_fixed "workers row count was 0"
require_fixed "user_sessions row count was 0"
require_fixed "router_logs row count was 0"
require_fixed "edge-queue-controller.service was disabled"
require_fixed "edge-queue-controller.service was inactive"
require_fixed "unit ExecStart binds Uvicorn to 127.0.0.1:7070"
require_fixed "unit contains no public API key"
require_fixed "unit contains no secret token"
require_fixed "unit contains no password"
require_fixed "unit contains no auth URL"
require_fixed "controller runtime port listeners were absent on 7070, 17070, 17071, and 17072"
require_fixed "private edge-controller LXC exists"
require_fixed "auth/session/credit schema repaired"
require_fixed "private auth-flow smoke passed with temporary in-process public API key"
require_fixed "private system/queue route smoke passed"
require_fixed "default-off systemd unit drafted"
require_fixed "manual systemd start, loopback smoke, stop, and no-enable smoke passed"
require_fixed "startup boot guard/no-autostart/no-enable regression passed"
require_fixed "Data authority decision is still unresolved"
require_fixed "Secret and public API key persistence policy is unresolved"
require_fixed "Persistent CT202 runtime remains disabled"
require_fixed "Public routing remains untouched"
require_fixed "Laptop controller remains live authority"
require_fixed "Worker/model runtime remains out of scope"
require_fixed "Operational rollback needs a written plan"
require_fixed "Source refresh is recommended before any cutover execution approval"
require_fixed "CT 202 is still not authoritative"
require_fixed "CT202 service unit exists, but it remains disabled and inactive"
require_fixed "CT202 is not configured to autostart as a controller runtime"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
require_fixed "no systemctl start"
require_fixed "no systemctl enable"
require_fixed "no systemctl daemon-reload"
require_fixed "no pct set"
require_fixed "no reboot"
require_fixed "no persistent controller runtime activation"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_gs_source_refresh_or_ct202_cutover_plan_no_apply_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
