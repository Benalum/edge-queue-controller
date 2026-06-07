#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 dormant worker path plan static check ==="

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

require_file docs/ct101-dormant-worker-path-inspection-notes.md
require_file docs/ct101-dormant-worker-path-plan.md
require_file docs/ct101-dormant-client-one-shot-smoke.md
require_file docs/ct101-dormant-laptop-queue-client-tracking.md

require_fixed docs/ct101-dormant-worker-path-plan.md "planning only" "planning only"
require_fixed docs/ct101-dormant-worker-path-plan.md "No CT101 files are modified" "no CT101 writes"
require_fixed docs/ct101-dormant-worker-path-plan.md "disabled by default" "disabled by default"
require_fixed docs/ct101-dormant-worker-path-plan.md "LAPTOP_QUEUE_ENABLED=1" "enabled flag"
require_fixed docs/ct101-dormant-worker-path-plan.md "LAPTOP_QUEUE_SYNTHETIC_ONLY=1" "synthetic only flag"
require_fixed docs/ct101-dormant-worker-path-plan.md "LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env" "token file flag"
require_fixed docs/ct101-dormant-worker-path-plan.md "run_laptop_queue_worker_once" "future insertion point"
require_fixed docs/ct101-dormant-worker-path-plan.md "refuse non-synthetic job IDs" "non-synthetic refusal"
require_fixed docs/ct101-dormant-worker-path-plan.md "never run automatically from Docker Compose" "no compose auto-run"
require_fixed docs/ct101-dormant-worker-path-plan.md "laptop queue heartbeat endpoint" "heartbeat gap"
require_fixed docs/ct101-dormant-worker-path-plan.md "stuck running job recovery" "recovery gap"
require_fixed docs/ct101-dormant-worker-path-plan.md "idempotent completion behavior" "idempotency gap"
require_fixed docs/ct101-dormant-worker-path-plan.md "Docker Compose changes" "postpone compose"
require_fixed docs/ct101-dormant-worker-path-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/ct101-dormant-worker-path-plan.md "Do not:" "constraints present"
require_fixed docs/ct101-dormant-worker-path-plan.md "modify production worker loop" "do not modify worker loop"

require_fixed docs/ct101-dormant-worker-path-inspection-notes.md "backend/app/worker/agent.py" "worker loop inspected"
require_fixed docs/ct101-dormant-worker-path-inspection-notes.md "backend/app/worker/laptop_queue_client.py" "dormant client inspected"
require_fixed docs/ct101-dormant-worker-path-inspection-notes.md "docker-compose.yml" "compose inspected"

echo "PASS: CT101 dormant worker path plan markers are present"
