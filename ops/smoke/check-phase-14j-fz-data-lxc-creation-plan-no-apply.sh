#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-fz-data-lxc-creation-plan-no-apply"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-fy-proxmox-data-target-inventory-no-creation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

"$PREV_SMOKE" >/tmp/apc-fy-smoke.out
echo "PASS: previous Phase 14J-FY smoke regression passed"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- phase markers ---"
require_fixed "PHASE_14J_FZ_DATA_LXC_CREATION_PLAN_NO_APPLY"
require_fixed "PHASE_14J_FZ_RESULT=data_lxc_creation_plan_recorded_no_apply"
require_fixed "PHASE_14J_FZ_PLANNED_CT_ID=201"
require_fixed "PHASE_14J_FZ_PLANNED_HOSTNAME=edge-data"
require_fixed "PHASE_14J_FZ_PLANNED_KIND=private_lxc_data_container"
require_fixed "NEXT_SAFE_PHASE=phase_14j_ga_private_edge_data_lxc_creation_apply_requires_explicit_approval"

echo "--- plan markers ---"
require_fixed "root disk storage: local-lvm"
require_fixed "data/backup storage: data-2tb"
require_fixed "/srv/edge-data/sqlite-backups"
require_fixed "/srv/edge-data/restore-drills"
require_fixed "/srv/edge-data/live/edge_queue.sqlite3"
require_fixed "APPROVE_PHASE_14J_GA_CREATE_PRIVATE_EDGE_DATA_LXC_201"

echo "--- hard denial markers ---"
require_fixed "no container creation"
require_fixed "no VM creation"
require_fixed "no pct create"
require_fixed "no pct start"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no runtime config change"
require_fixed "no systemd mutation"
require_fixed "no env file mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Cloudflare route mutation"
require_fixed "no raw IP recording"
require_fixed "no auth URL recording"

echo "--- doc secret/raw endpoint guard ---"
if grep -Eq 'https://login\.tailscale\.com|eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible auth URL/secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
