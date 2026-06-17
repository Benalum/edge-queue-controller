#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gd-private-edge-controller-lxc-creation-record"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gc-r0-controller-data-split-pivot-plan-no-apply.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gc-r0-smoke.out
echo "PASS: previous Phase 14J-GC-R0 smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GD_PRIVATE_EDGE_CONTROLLER_LXC_CREATION_RECORD"
require_fixed "PHASE_14J_GD_RESULT=private_edge_controller_lxc_created_and_verified_stopped_no_runtime_activation"
require_fixed "APPROVE_PHASE_14J_GD_CREATE_PRIVATE_EDGE_CONTROLLER_LXC_202"
require_fixed "PHASE_14J_GD_CREATED_CT_ID=202"
require_fixed "PHASE_14J_GD_CREATED_HOSTNAME=edge-controller"
require_fixed "PHASE_14J_GD_CREATED_KIND=private_lxc_controller_queue_container"
require_fixed "status: stopped"
require_fixed "onboot: 0"
require_fixed "unprivileged: 1"
require_fixed "rootfs: local-lvm, 16G"
require_fixed "PHASE_14J_GD_STORAGE_RISK_NOTE=local_lvm_thin_pool_overcommit_warning_observed"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "CT 202 is not yet running controller API, queue scheduler, auth, worker, or model runtime"
require_fixed "no pct create rerun"
require_fixed "no pct start"
require_fixed "no package install"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no laptop service stop"
require_fixed "no service restart/reload"
require_fixed "no runtime config change"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_ge_edge_controller_lxc_baseline_package_plan_no_start"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
