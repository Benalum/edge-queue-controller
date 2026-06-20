#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-e0-pveso-offline-autopower-primary-worker-plan-no-apply.md"

echo "=== Stage 16-E0 smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-E0 doc missing"
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

require_text "PVESO Offline Auto-Power Primary Worker Plan, No Apply"
require_text "PVESO is intentionally offline by default."
require_text "PVESO should become the main on-demand model worker host"
require_text "PVEW remains the always-on platform host."
require_text "CT203 on PVEW remains controller, API, queue, and decision authority."
require_text "VM200 on PVEW remains public/static edge."
require_text "CT204 on PVEW remains stopped backup-data-only."
require_text "PVEW may later host a replica/helper model worker"
require_text "Auto-power must be separate from model execution."
require_text "Waking PVESO must not automatically run a model job."
require_text "The queue should remain durable while PVESO is offline."
require_text "Stage 16-E1 — auto-power design, no apply"
require_text "APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB"
require_text "APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION"
require_text "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"
require_text "Do not install Ollama on PVEW as the first path."
require_text "Do design PVESO auto-power first."

echo "PASS_STAGE_16_E0_SMOKE"
