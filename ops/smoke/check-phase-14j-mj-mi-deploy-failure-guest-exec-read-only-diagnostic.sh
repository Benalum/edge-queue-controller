#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mj-mi-deploy-failure-guest-exec-read-only-diagnostic"
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

require "Phase 14J-MJ"
require "MI Deploy Failure Guest Exec Read-Only Diagnostic"
require "498baad"
require "controller-phase-14j-mh-vm200-qga-command-compatibility-read-only-2026-06-18"
require "pvew_qemu_guest_agent_preflight=pass"
require "public_app_state_after_failed_mi="
require "public_status_http=200"
require "node_ids_sorted=ct-203,ct-204,pvew,vm-200"
require "storage_policy=manual-unlock-only"
require "ct204_data_authority=false"
require "The guest exec checks executed only \`/bin/true\`."
require "pvew_ssh_connect=pass"
require "pvew_remote_user=root"
require "pvew_qm_binary=present"
require "vm200_status=running"
require "qm_guest_cmd_ping_exitcode=0"
require "vm200_qga_cmd_ping=pass"
require "guest_exec_dashdash_start_exitcode="
require "guest_exec_nodash_start_exitcode="
require "guest_exec_supported_form="
require "next_step_summary="
require "No VM200 app.js write"
require "no frontend deploy"
require "no Cloudflare/DNS/tunnel mutation"
require "no service restart/reload/enable/start/stop"
require "no DB restore/import/migration"
require "no storage unlock/mount/format/key/crypttab/fstab mutation"
require "no CT204 start"
require "no PVESO wake/start"
require "PASS_PHASE_14J_MJ_MI_DEPLOY_FAILURE_GUEST_EXEC_READ_ONLY_DIAGNOSTIC_DONE"

echo "PASS: 14J-MJ MI deploy failure guest exec diagnostic evidence present"
echo "PASS_${PHASE}"
