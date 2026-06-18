#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-ge-edge-controller-baseline-setup-record"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gd-private-edge-controller-lxc-creation-record.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gd-smoke.out
echo "PASS: previous Phase 14J-GD smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GE_EDGE_CONTROLLER_BASELINE_SETUP_RECORD"
require_fixed "PHASE_14J_GE_RESULT=edge_controller_baseline_setup_completed_no_runtime_activation"
require_fixed "APPROVE_PHASE_14J_GE_START_EDGE_CONTROLLER_BASELINE_SETUP_ONLY"
require_fixed "PHASE_14J_GE_CT_ID=202"
require_fixed "PHASE_14J_GE_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GE_STATUS=running"
require_fixed "/srv/edge-controller/app"
require_fixed "/srv/edge-controller/data"
require_fixed "/srv/edge-controller/backups"
require_fixed "/srv/edge-controller/logs"
require_fixed "FORBIDDEN_ABSENT=docker"
require_fixed "FORBIDDEN_ABSENT=node"
require_fixed "FORBIDDEN_ABSENT=npm"
require_fixed "FORBIDDEN_ABSENT=nginx"
require_fixed "FORBIDDEN_ABSENT=cloudflared"
require_fixed "FORBIDDEN_ABSENT=ollama"
require_fixed "no controller code clone"
require_fixed "no controller runtime activation"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no laptop controller stop"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "CT 202 is not yet authoritative"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gf_clone_controller_code_default_off_no_runtime_activation"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
