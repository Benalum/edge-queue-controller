#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-e1a-existing-pveso-autopower-endpoint-rediscovery-no-apply.md"

echo "=== Stage 16-E1A smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-E1A doc missing"
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

require_text "Existing PVESO Auto-Power Endpoint Rediscovery, No Apply"
require_text "It does not wake PVESO."
require_text "It does not mutate PVESO."
require_text "It does not write the database."
require_text "It does not activate workers."
require_text "It does not activate schedulers."
require_text "It does not invoke any power, wake, boot, or shutdown endpoint."
require_text "Before designing anything new, Stage 16-E1A rediscovers existing code and deployed endpoint paths."
require_text "PVESO is the primary on-demand model worker host."
require_text "If existing PVESO power endpoints are present, reuse them rather than inventing a new control surface."
require_text "Stage 16-E1B should convert the rediscovered endpoint inventory into an exact no-apply auto-power controller design."
require_text "APPROVE_STAGE_16_E2_PVESO_WAKE_READINESS_INVENTORY_NO_WORKER_NO_MODEL_JOB"
require_text "APPROVE_STAGE_16_F_PVESO_LLMS_WORKER_BRIDGE_PREP_NO_MODEL_JOB_NO_SCHEDULER_BROAD_ACTIVATION"
require_text "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"

echo "PASS_STAGE_16_E1A_SMOKE"
