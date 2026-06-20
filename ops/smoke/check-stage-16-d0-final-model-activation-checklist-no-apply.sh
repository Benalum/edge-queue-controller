#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-d0-final-model-activation-checklist-no-apply.md"

echo "=== Stage 16-D0 smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-D0 doc missing"
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

require_text "Final Model Activation Checklist, No Apply"
require_text "It does not approve or perform model activation."
require_text "It does not write the database."
require_text "It does not call Ollama."
require_text "It does not call model endpoints."
require_text "It does not run ollama list, ollama pull, ollama run, or ollama show."
require_text "selected target: pvew-local-ollama-candidate"
require_text "worker id: stage16-local-model-worker-1"
require_text "queue job type: companion.chat"
require_text "first small model candidate: qwen2.5:0.5b"
require_text "APPROVE_STAGE_16_D_ONE_CONTROLLED_QUEUE_MODEL_TEST"
require_text "Users must never talk directly to models."
require_text "Frontend -> CT203 API -> durable job row -> explicit decision/scheduler policy -> default-off worker path -> model runtime -> job_results row -> frontend poll."
require_text "Direct /tick/ollama-direct remains blocked for this rollout path."
require_text "jobs: +1"
require_text "job_results: +1"
require_text "CT204 remains stopped"
require_text "private storage remains locked"

echo "PASS_STAGE_16_D0_SMOKE"
