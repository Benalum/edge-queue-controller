#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gc-r0-controller-data-split-pivot-plan-no-apply"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-gb-private-edge-data-lxc-post-create-verify-and-baseline-plan-no-start.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-gb-smoke.out
echo "PASS: previous Phase 14J-GB smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GC_R0_CONTROLLER_DATA_SPLIT_PIVOT_PLAN_NO_APPLY"
require_fixed "PHASE_14J_GC_R0_RESULT=controller_data_split_pivot_plan_recorded_no_apply"
require_fixed "PHASE_14J_GC_R0_SQLITE_DECISION=controller_container_local_sqlite_first"
require_fixed "PHASE_14J_GC_R0_DATA_POSTURE=fresh_or_selective_import_allowed"
require_fixed "VM 200 website-edge"
require_fixed "CT 201 edge-data"
require_fixed "Planned CT 202 edge-controller"
require_fixed "CT 101 llms"
require_fixed "should own its local live SQLite database at first"
require_fixed "should not use a network-mounted SQLite file from CT 201"
require_fixed "network-mounted SQLite can create locking/corruption risk"
require_fixed "APPROVE_PHASE_14J_GD_CREATE_PRIVATE_EDGE_CONTROLLER_LXC_202"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gd_private_edge_controller_lxc_creation_requires_explicit_approval"

require_fixed "no container creation"
require_fixed "no pct create"
require_fixed "no pct start"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no runtime config change"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
