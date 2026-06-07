#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 worker laptop queue integration plan static check ==="

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

require_file docs/ct101-worker-laptop-queue-inspection-notes.md
require_file docs/ct101-worker-laptop-queue-integration-plan.md
require_file docs/ct101-laptop-queue-synthetic-lifecycle.md
require_file docs/ct101-laptop-queue-readonly-connectivity.md

require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "inspection and planning only" "inspection/planning only"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "No CT101 files are modified." "no CT101 modification"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "explicitly opt-in synthetic-only laptop queue mode" "synthetic-only opt-in"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "LAPTOP_QUEUE_ENABLED=1" "future enabled flag"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "LAPTOP_QUEUE_SYNTHETIC_ONLY=1" "future synthetic-only flag"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env" "future token file"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "refuses jobs without a synthetic/stage prefix" "synthetic guardrail"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "does not alter the always-running CT101 worker service" "do not alter current worker"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "Do not:" "constraints"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "modify the main CT101 worker loop yet" "no main worker loop change"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "duplicate queues accepting the same production job" "duplicate queue risk"
require_fixed docs/ct101-worker-laptop-queue-integration-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"

require_fixed docs/ct101-worker-laptop-queue-inspection-notes.md "backend/app/worker/agent.py" "worker agent inspected"
require_fixed docs/ct101-worker-laptop-queue-inspection-notes.md "backend/app/routes/jobs.py" "jobs route inspected"
require_fixed docs/ct101-worker-laptop-queue-inspection-notes.md "docker-compose.yml" "compose inspected"

echo "PASS: CT101 worker laptop queue integration plan markers are present"
