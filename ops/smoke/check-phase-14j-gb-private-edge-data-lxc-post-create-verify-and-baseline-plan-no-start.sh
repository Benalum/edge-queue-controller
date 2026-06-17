#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-gb-private-edge-data-lxc-post-create-verify-and-baseline-plan-no-start"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-ga-private-edge-data-lxc-creation-record.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-ga-smoke.out
echo "PASS: previous Phase 14J-GA smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

require_fixed "PHASE_14J_GB_PRIVATE_EDGE_DATA_LXC_POST_CREATE_VERIFY_AND_BASELINE_PLAN_NO_START"
require_fixed "PHASE_14J_GB_RESULT=private_edge_data_lxc_verified_baseline_plan_recorded_no_start"
require_fixed "PHASE_14J_GB_VERIFIED_CT_ID=201"
require_fixed "PHASE_14J_GB_VERIFIED_HOSTNAME=edge-data"
require_fixed "PHASE_14J_GB_VERIFIED_STATUS=stopped"
require_fixed "laptop-local edge_queue.sqlite3 remains the live primary controller platform data authority"
require_fixed "CT 201 is not authoritative"
require_fixed "APPROVE_PHASE_14J_GC_START_EDGE_DATA_LXC_BASELINE_SETUP_ONLY"
require_fixed "/srv/edge-data/sqlite-backups"
require_fixed "/srv/edge-data/restore-drills"
require_fixed "/srv/edge-data/live"
require_fixed "no cloudflared, no nginx, no Docker, no Node/npm, no Ollama, no worker service, and no controller service"
require_fixed "no pct start"
require_fixed "no package install"
require_fixed "no data directory creation"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no Cloudflare route mutation"
require_fixed "no public route"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"
require_fixed "NEXT_SAFE_PHASE=phase_14j_gc_start_edge_data_lxc_baseline_setup_only_requires_explicit_approval"

if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
