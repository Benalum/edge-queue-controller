#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 real Ollama laptop queue plan static check ==="

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_fixed() {
  local file="$1"
  local text="$2"
  local label="$3"

  if grep -F -n "$text" "$file" >/dev/null 2>&1; then
    echo "OK: $label"
  else
    echo "FAIL: missing $label"
    echo "  file: $file"
    echo "  text: $text"
    exit 1
  fi
}

require_file docs/ct101-ollama-laptop-queue-inspection-notes.md
require_file docs/ct101-real-ollama-laptop-queue-plan.md
require_file docs/ct101-bounded-synthetic-poller-smoke.md
require_file docs/ct101-dormant-synthetic-polling-plan.md
require_file docs/laptop-queue-idempotent-completion.md
require_file docs/laptop-queue-synthetic-recovery.md

require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "planning and read-only inspection only" "planning/read-only"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "No CT101 files are modified" "no CT101 modifications"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "No bounded poller calls real Ollama in this stage." "no Ollama call this stage"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "LAPTOP_QUEUE_EXECUTION_MODE=ollama" "execution mode flag"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "LAPTOP_QUEUE_OLLAMA_BASE_URL=http://127.0.0.1:11434" "Ollama base URL flag"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "LAPTOP_QUEUE_OLLAMA_TIMEOUT_SECONDS" "Ollama timeout flag"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK" "Ollama fallback model flag"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "Without that flag, it should keep deterministic synthetic result behavior." "deterministic default"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "payload_json contains a prompt or messages field" "payload contract"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "elapsed_seconds" "result elapsed field"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "ct101_bounded_ollama_poller" "source marker"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "fail the job" "failure behavior"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "heartbeat busy with current_job_id" "busy heartbeat"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "late completion after recovery should be rejected" "recovery/idempotency"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "prefer job.requested_model" "model preference"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "add CT101 smoke-only real-Ollama bounded poller mode" "next stage scope"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "verify worker returns idle" "worker idle verification"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "Do not:" "constraints present"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "implement real Ollama poller yet" "do not implement yet"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "claim real jobs" "do not claim real jobs"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "Production chat migration should wait" "migration postponed"
require_fixed docs/ct101-real-ollama-laptop-queue-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"

require_fixed docs/ct101-ollama-laptop-queue-inspection-notes.md "backend/app/worker/agent.py" "worker inspected"
require_fixed docs/ct101-ollama-laptop-queue-inspection-notes.md "ops/smoke/laptop_queue_bounded_synthetic_poller.py" "bounded poller inspected"
require_fixed docs/ct101-ollama-laptop-queue-inspection-notes.md "docker-compose.yml" "compose inspected"

echo "PASS: CT101 real Ollama laptop queue plan markers are present"
