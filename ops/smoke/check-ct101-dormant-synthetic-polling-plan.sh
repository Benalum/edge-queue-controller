#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 dormant synthetic polling plan static check ==="

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

require_file docs/ct101-dormant-synthetic-polling-plan.md
require_file docs/laptop-queue-idempotent-completion.md
require_file docs/laptop-queue-synthetic-recovery.md
require_file docs/laptop-queue-worker-register-heartbeat.md
require_file docs/ct101-dormant-worker-path-plan.md

require_fixed docs/ct101-dormant-synthetic-polling-plan.md "planning only" "planning only"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "No persistent worker is implemented in this stage." "no persistent worker"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "LAPTOP_QUEUE_ENABLED=1" "enabled flag"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "LAPTOP_QUEUE_SYNTHETIC_ONLY=1" "synthetic-only flag"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "LAPTOP_QUEUE_POLL_MODE=bounded" "bounded mode flag"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "LAPTOP_QUEUE_MAX_JOBS_PER_RUN" "max jobs flag"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "LAPTOP_QUEUE_POLL_INTERVAL_SECONDS" "poll interval flag"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "disabled by default" "disabled by default"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "must not be added to Docker Compose yet" "no Docker Compose"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "refuse non-synthetic job IDs" "refuse non-synthetic"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "no infinite loop" "no infinite loop"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "POST /internal/laptop-queue/workers/register" "register heartbeat flow"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "POST /internal/laptop-queue/workers/heartbeat with busy and current_job_id after claim" "busy heartbeat"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "Do not call real Ollama in the first bounded poller stage." "no real Ollama"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "Stage 5E-19 should add a CT101 smoke-only bounded synthetic poller." "next stage"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "process at most two synthetic jobs" "bounded synthetic processing"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "Do not:" "constraints present"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "implement persistent polling" "do not implement persistent polling"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "modify CT101 files" "do not modify CT101 in this stage"
require_fixed docs/ct101-dormant-synthetic-polling-plan.md "claim real jobs" "do not claim real jobs"

echo "PASS: CT101 dormant synthetic polling plan markers are present"
