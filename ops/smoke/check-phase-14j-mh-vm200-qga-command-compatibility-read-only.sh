#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mh-vm200-qga-command-compatibility-read-only"
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

require "Phase 14J-MH"
require "VM200 QGA Command Compatibility Read-Only"
require "4eff0e6"
require "controller-phase-14j-mg-vm200-qga-preflight-blocker-read-only-diagnostic-2026-06-18"
require "qm guest ping 200"
require "qm guest cmd <vmid> <command>"
require "qm guest cmd 200 ping"
require "public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public_status_http=200"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "ct204_data_authority=false"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "pvew_qm_binary=present"
require "qm_status_exitcode=0"
require "vm200_status=running"
require "qm_guest_cmd_ping_exitcode="
require "vm200_qga_cmd_ping="
require "blocker_summary="
require "No VM200 write"
require "no guest exec"
require "no qemu guest-agent mutation"
require "no SSH config mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "APPROVE_PHASE_14J_MI_RETRY_DEPLOY_VM200_WRAPPER_APP_ASSET_ONLY_CORRECTED_QGA_CMD"
require "PASS_PHASE_14J_MH_VM200_QGA_COMMAND_COMPATIBILITY_READ_ONLY_DONE"

echo "PASS: 14J-MH VM200 QGA command compatibility evidence present"
echo "PASS_${PHASE}"
