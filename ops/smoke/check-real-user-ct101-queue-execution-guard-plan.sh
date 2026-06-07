#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user CT101 queue execution guard plan static check ==="

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

require_file docs/real-user-ct101-queue-execution-guard-plan.md
require_file docs/real-user-queued-chat-status-route.md
require_file docs/real-user-queued-chat-route-creation.md
require_file docs/synthetic-queued-chat-route-ct101-lifecycle.md

require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "planning only" "planning only"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "No production worker behavior changes happen in this stage." "no worker changes"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1" "real-user worker flag"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "Enabling LAPTOP_QUEUE_ENABLED alone must not allow real-user job execution." "flag safety"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "run bounded one-shot first" "bounded first"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "avoid logging secrets or session tokens" "no secret logging"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "return only user-owned job status" "owned status"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "persist assistant message only after complete job owned by the authenticated user" "owned persistence"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "This stage does not:" "constraints present"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "allow CT101 to claim real-user jobs" "no real-user claim yet"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "Stage 5F-22 should add a dormant CT101 real-user execution guard" "next stage"
require_fixed docs/real-user-ct101-queue-execution-guard-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"

echo "PASS: real-user CT101 queue execution guard plan markers are present"
