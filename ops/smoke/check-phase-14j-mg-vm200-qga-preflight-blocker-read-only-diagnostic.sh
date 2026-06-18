#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mg-vm200-qga-preflight-blocker-read-only-diagnostic"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

require() {
  local pattern="$1"
  if ! grep -Fq "$pattern" "$DOC"; then
    echo "FAIL: missing required pattern: $pattern"
    exit 1
  fi
}

test -f "$DOC"

require "Phase 14J-MG"
require "VM200 QGA Preflight Blocker Read-Only Diagnostic"
require "256f644"
require "controller-phase-14j-me-update-workstation-pvew-alias-user-root-only-2026-06-18"
require "ssh_g_user=root"
require "pvew_ssh_preflight_exitcode=10"
require "qm/qemu guest-agent preflight failed for VM200"
require "public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public_status_http=200"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "ct204_data_authority=false"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "pvew_qm_binary=present"
require "qm_status_exitcode="
require "vm200_status="
require "qm_guest_ping_exitcode="
require "vm200_qga_ping="
require "blocker_summary="
require "No VM200 write"
require "no qemu guest-agent mutation"
require "no guest exec mutation"
require "no SSH config mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MG_VM200_QGA_PREFLIGHT_BLOCKER_READ_ONLY_DIAGNOSTIC_DONE"

echo "PASS: 14J-MG read-only VM200 QGA blocker diagnostic evidence present"
echo "PASS_${PHASE}"
