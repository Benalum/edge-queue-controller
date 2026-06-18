#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gn-ct202-default-off-controller-systemd-unit-draft-no-enable-no-start"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gm-ct202-private-system-queue-route-runtime-smoke-temporary-only.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gm-smoke.out
echo "PASS: previous Phase 14J-GM smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GN_CT202_DEFAULT_OFF_CONTROLLER_SYSTEMD_UNIT_DRAFT_NO_ENABLE_NO_START"
require_fixed "PHASE_14J_GN_RESULT=ct202_default_off_controller_systemd_unit_draft_created_no_enable_no_start"
require_fixed "APPROVE_PHASE_14J_GN_CT202_DEFAULT_OFF_CONTROLLER_SYSTEMD_UNIT_DRAFT_NO_ENABLE_NO_START"
require_fixed "PHASE_14J_GN_CT_ID=202"
require_fixed "PHASE_14J_GN_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GN_STATUS=running"
require_fixed "PHASE_14J_GN_UNIT_PATH=/etc/systemd/system/edge-queue-controller.service"
require_fixed "PHASE_14J_GN_DB_PATH=/srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "unit file was created at /etc/systemd/system/edge-queue-controller.service"
require_fixed "systemctl daemon-reload was run"
require_fixed "unit file state was disabled"
require_fixed "unit active state was inactive"
require_fixed "unit ExecStart uses /srv/edge-controller/venv/bin/python -m uvicorn edge_controller:app"
require_fixed "unit bind host is 127.0.0.1"
require_fixed "unit bind port is 7070"
require_fixed "unit DB path is /srv/edge-controller/data/edge_queue.sqlite3"
require_fixed "unit contains no public API key"
require_fixed "unit contains no secret token"
require_fixed "unit contains no password"
require_fixed "unit contains no auth URL"
require_fixed "edge controller Uvicorn process was absent after the draft"
require_fixed "SQLite quick_check passed after the draft"
require_fixed "CT202 service unit exists, but it is disabled and inactive"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "laptop controller service remains the live controller"
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
require_fixed "NEXT_SAFE_PHASE=phase_14j_go_ct202_systemd_unit_static_smoke_and_disabled_state_regression_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
