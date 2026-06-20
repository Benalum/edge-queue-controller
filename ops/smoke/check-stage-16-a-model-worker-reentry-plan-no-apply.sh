#!/usr/bin/env bash
set -euo pipefail
set +H

DOC="docs/stage-16-a-model-worker-reentry-plan-no-apply.md"

echo "=== Stage 16-A smoke ==="

if [ ! -f "$DOC" ]; then
  echo "FAIL: Stage 16-A doc missing"
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

require_text "Model Worker Re-entry Plan, No Apply"
require_text "Users must still never talk directly to models."
require_text "Frontend -> CT203 API -> durable job row -> scheduler/decision policy -> worker -> model -> job result -> frontend poll."
require_text "The first model re-entry must therefore go through the queue path, not through /tick/ollama-direct."
require_text "Stage 16-B — model target inventory, no apply"
require_text "Stage 16-C — worker/scheduler contract patch, default off"
require_text "Stage 16-D — one controlled mock-to-real queue test, explicit approval required"
require_text "worker activation"
require_text "scheduler activation"
require_text "Ollama endpoint calls"
require_text "live model endpoint calls"
require_text "private storage remains locked"
require_text "pvescheduler.service is Proxmox VE scheduler"
require_text "Linux kernel worker threads, not AI Platform worker activation"

echo "PASS_STAGE_16_A_SMOKE"
