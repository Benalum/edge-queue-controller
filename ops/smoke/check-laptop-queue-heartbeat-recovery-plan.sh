#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop queue heartbeat/recovery plan static check ==="

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

require_file docs/laptop-queue-heartbeat-recovery-inspection-notes.md
require_file docs/laptop-queue-heartbeat-recovery-plan.md
require_file docs/ct101-dormant-worker-path-plan.md
require_file docs/laptop-job-queue-facade-plan.md

require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "planning only" "planning only"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "No runtime behavior changes happen in this stage." "no runtime changes"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "worker registration endpoint" "worker registration gap"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "worker heartbeat endpoint" "worker heartbeat gap"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "worker offline/stale detection" "stale worker gap"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "stuck running job recovery" "stuck job recovery gap"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "idempotent completion behavior" "idempotent completion gap"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "POST /internal/laptop-queue/workers/register" "future register endpoint"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "POST /internal/laptop-queue/workers/heartbeat" "future heartbeat endpoint"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "POST /internal/laptop-queue/recover" "future recover endpoint"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Registration must be idempotent." "idempotent registration"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Heartbeat must not complete jobs." "heartbeat does not complete jobs"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Do not requeue jobs until retry_count and max_retries exist." "no requeue yet"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "completing already complete job with matching result can return current job without mutation" "duplicate complete plan"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "app_jobs.lease_expires_at" "future lease field"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Do not add these fields in Stage 5E-14." "no schema changes"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "add laptop queue worker register endpoint" "Stage 5E-15 scope"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "add laptop queue recovery endpoint" "Stage 5E-16 scope"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "persistent CT101 worker polling" "persistent polling postponed"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "Do not:" "constraints present"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "add heartbeat endpoints yet" "no heartbeat implementation"
require_fixed docs/laptop-queue-heartbeat-recovery-plan.md "add recovery endpoints yet" "no recovery implementation"

require_fixed docs/laptop-queue-heartbeat-recovery-inspection-notes.md "edge_controller.py" "edge controller inspected"
require_fixed docs/laptop-queue-heartbeat-recovery-inspection-notes.md "edge_modules/laptop_queue.py" "laptop queue helper inspected"
require_fixed docs/laptop-queue-heartbeat-recovery-inspection-notes.md "ops/db/laptop-app-schema-v1.sql" "schema inspected"

echo "PASS: laptop queue heartbeat/recovery plan markers are present"
