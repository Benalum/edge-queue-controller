#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-ga-private-edge-data-lxc-creation-record"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-fz-data-lxc-creation-plan-no-apply.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-fz-smoke.out
echo "PASS: previous Phase 14J-FZ smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GA_PRIVATE_EDGE_DATA_LXC_CREATION_RECORD"
require_fixed "PHASE_14J_GA_RESULT=private_edge_data_lxc_created_and_verified_stopped_no_data_migration"
require_fixed "APPROVE_PHASE_14J_GA_CREATE_PRIVATE_EDGE_DATA_LXC_201"
require_fixed "PHASE_14J_GA_CREATED_CT_ID=201"
require_fixed "PHASE_14J_GA_CREATED_HOSTNAME=edge-data"
require_fixed "PHASE_14J_GA_CREATED_KIND=private_lxc_data_container"
require_fixed "status: stopped"
require_fixed "onboot: 0"
require_fixed "unprivileged: 1"
require_fixed "rootfs: local-lvm, 8G"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "CT 201 is not authoritative"
require_fixed "no pct create rerun"
require_fixed "no pct start"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gb_private_edge_data_lxc_post_create_verify_and_baseline_plan_no_start"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
