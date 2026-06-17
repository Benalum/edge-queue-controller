#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-fx-data-container-or-vm-target-design-no-creation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-fw-default-preserving-controller-db-path-env-override-no-runtime-reload.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- previous smoke regression ---"
"$PREV_SMOKE"

echo "--- phase markers ---"
require_fixed "PHASE_14J_FX_DATA_CONTAINER_OR_VM_TARGET_DESIGN_NO_CREATION"
require_fixed "PHASE_14J_FX_RESULT=data_target_design_recorded_no_creation"
require_fixed "PHASE_14J_FX_RECOMMENDED_TARGET=private_lxc_data_container_not_public_vm"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fy_read_only_proxmox_data_target_inventory_no_creation"

echo "--- design markers ---"
require_fixed "private LXC data container"
require_fixed "no public routes"
require_fixed "no Cloudflare tunnel"
require_fixed "rollback to laptop-local edge_queue.sqlite3"
require_fixed "EDGE_QUEUE_SQLITE_DB_PATH"
require_fixed "restore drill on target"

echo "--- hard-denial markers ---"
require_fixed "no container creation"
require_fixed "no VM creation"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no runtime config change"
require_fixed "no systemd mutation"
require_fixed "no env file mutation"
require_fixed "no worker start"
require_fixed "no production DB/job mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Cloudflare route mutation"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "--- doc secret/raw endpoint guard ---"
if grep -Eq 'eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
