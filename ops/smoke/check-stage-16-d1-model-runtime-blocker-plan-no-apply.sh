#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-d1-model-runtime-blocker-plan-no-apply.md"

echo "=== Stage 16-D1 smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-D1 doc missing"
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

require_text "Model Runtime Blocker Plan, No Apply"
require_text "Stage 16-D one controlled real-model queue test is blocked."
require_text "PVEW Ollama binary was absent."
require_text "PVEW model storage candidates were missing."
require_text "CT203 Ollama binary was absent."
require_text "VM200 Ollama binary was absent."
require_text "Stage 16-E no-apply runtime provisioning plan"
require_text "APPROVE_STAGE_16_E_PVEW_OLLAMA_RUNTIME_INSTALL_NO_WORKER_NO_SCHEDULER_NO_MODEL_JOB"
require_text "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"
require_text "worker activation"
require_text "scheduler activation"
require_text "DB job creation"
require_text "private storage remains locked"
require_text "CT204 remains stopped"
require_text "Runtime installation and real queued model execution must not be combined"

echo "PASS_STAGE_16_D1_SMOKE"
