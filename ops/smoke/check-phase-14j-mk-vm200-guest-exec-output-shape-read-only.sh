#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mk-vm200-guest-exec-output-shape-read-only"
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

require "Phase 14J-MK"
require "VM200 Guest Exec Output Shape Read-Only"
require "8b1f250"
require "controller-phase-14j-mj-mi-deploy-failure-guest-exec-read-only-diagnostic-2026-06-18"
require "public_app_sha=dab59fa04e0ebe7478b1316771cb0437e3d2e8ad1fb0f6eb7486c57d5c898812"
require "public_status_http=200"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "ct204_data_authority=false"
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "vm200_status=running"
require "vm200_qga_cmd_ping=pass"
require "guest_exec_dashdash_start_exitcode="
require "guest_exec_nodash_start_exitcode="
require "guest_exec_sync_probe_start_exitcode="
require "guest_exec_strategy="
require "next_step_summary="
require "No VM200 app.js write"
require "no frontend deploy"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MK_VM200_GUEST_EXEC_OUTPUT_SHAPE_READ_ONLY_DONE"

echo "PASS: 14J-MK VM200 guest exec output-shape evidence present"
echo "PASS_${PHASE}"
