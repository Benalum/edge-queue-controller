#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-b-model-target-inventory-no-apply.md"

echo "=== Stage 16-B smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-B doc missing"
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

require_text "Model Target Inventory, No Apply"
require_text "No DB writes were performed."
require_text "No Ollama endpoint calls were performed."
require_text "No model endpoint calls were performed."
require_text "No ollama list, ollama pull, ollama run, or ollama show command was executed."
require_text "Users must never talk directly to models."
require_text "Frontend -> CT203 API -> durable job row -> explicit decision/scheduler policy -> default-off worker path -> model runtime -> job_results row -> frontend poll."
require_text "Direct model calls and /tick/ollama-direct remain blocked for this rollout path."
require_text "Stage 16-C should patch or document a default-off queue-owned model worker path only."
require_text "Stage 16-D must require a separate explicit approval"
require_text "private storage remains locked"
require_text "CT204 remains stopped"
require_text "VM200 showed no Ollama binary."
require_text "No additional DB writes were performed in Stage 16-B."

echo "PASS_STAGE_16_B_SMOKE"
