#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-e1b-pveso-autopower-controller-design-no-apply.md"

echo "=== Stage 16-E1B smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-E1B doc missing"
  exit 1
fi

require_text() {
  needle="$1"
  if grep -F -- "$needle" "$DOC" >/dev/null 2>&1; then
    echo "PASS: found required text: $needle"
  else
    echo "FAIL: missing required text: $needle"
    exit 1
  fi
}

require_text "PVESO Auto-Power Controller Design, No Apply"
require_text "It does not wake PVESO."
require_text "It does not invoke any power, wake, boot, stop, shutdown, or worker-start endpoint."
require_text "/power/wake-plan"
require_text "/power/execute-wake"
require_text "/power/wake-and-start-worker-plan"
require_text "/power/execute-wake-and-start-worker"
require_text "/power/auto/status"
require_text "/system/pveso/boot"
require_text "execute-wake requires WAKE_PROXMOX_HOST confirmation."
require_text "execute-stop-plan requires STOP_AUTO_MANAGED_TARGETS confirmation."
require_text "execute-host-shutdown requires SHUTDOWN_PROXMOX_HOST confirmation."
require_text "PVESO is intentionally offline by default."
require_text "PVESO is the main on-demand model worker host."
require_text "CT203 on PVEW remains controller, API, queue, and decision authority."
require_text "Worker bridge activation and model execution remain separate gates."
require_text "APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB"
require_text "APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION"
require_text "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"
require_text "Stage 16-E2 should wake PVESO for readiness inventory only after explicit approval."

echo "PASS_STAGE_16_E1B_SMOKE"
