#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-fy-proxmox-data-target-inventory-no-creation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-fx-data-container-or-vm-target-design-no-creation.sh"

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
"$PREV_SMOKE" >/tmp/apc-fx-smoke.out
echo "PASS: previous Phase 14J-FX smoke regression passed"

echo "--- phase markers ---"
require_fixed "PHASE_14J_FY_PROXMOX_DATA_TARGET_INVENTORY_NO_CREATION"
require_fixed "PHASE_14J_FY_RESULT=proxmox_data_target_inventory_recorded_no_creation"
require_fixed "PHASE_14J_FY_RECOMMENDED_CT_ID=201"
require_fixed "PHASE_14J_FY_RECOMMENDED_TARGET_KIND=private_lxc_data_container"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fz_data_lxc_creation_plan_no_apply"

echo "--- inventory markers ---"
require_fixed "hostname: pveso"
require_fixed "pve-manager 9.1.5"
require_fixed "VM 101 named llms was stopped"
require_fixed "data-2tb: active"
require_fixed "local-lvm: active"
require_fixed "201 available"
require_fixed "215 available"
require_fixed "edge-data"

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
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
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
