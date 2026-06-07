#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== first production chat migration plan static check ==="

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

require_file docs/first-production-chat-migration-plan.md
require_file docs/ct101-bounded-ollama-failure-smoke.md
require_file docs/ct101-bounded-ollama-poller-smoke.md
require_file docs/laptop-queue-idempotent-completion.md
require_file docs/laptop-owned-data-plan.md
require_file docs/ct101-to-laptop-migration-map.md
require_file docs/single-frontend-owner-plan.md

require_fixed docs/first-production-chat-migration-plan.md "planning only" "planning only"
require_fixed docs/first-production-chat-migration-plan.md "No production chat behavior changes" "no production change"
require_fixed docs/first-production-chat-migration-plan.md "normal chat / ollama_chat" "first job type"
require_fixed docs/first-production-chat-migration-plan.md "Do not migrate study grading first." "study postponed"
require_fixed docs/first-production-chat-migration-plan.md "LAPTOP_CHAT_QUEUE_ENABLED=1" "chat queue flag"
require_fixed docs/first-production-chat-migration-plan.md "LAPTOP_CHAT_QUEUE_MODE=opt_in" "opt-in mode"
require_fixed docs/first-production-chat-migration-plan.md "Default behavior must remain unchanged" "default unchanged"
require_fixed docs/first-production-chat-migration-plan.md "create laptop queue job" "future job creation"
require_fixed docs/first-production-chat-migration-plan.md "frontend polls job status" "frontend polling"
require_fixed docs/first-production-chat-migration-plan.md "persist assistant message" "assistant persistence"
require_fixed docs/first-production-chat-migration-plan.md "duplicate completion does not duplicate assistant messages" "duplicate safety"
require_fixed docs/first-production-chat-migration-plan.md "failed jobs do not create assistant messages" "failure safety"
require_fixed docs/first-production-chat-migration-plan.md "disable LAPTOP_CHAT_QUEUE_ENABLED" "rollback flag"
require_fixed docs/first-production-chat-migration-plan.md "laptop wrapper still loads" "offline wrapper"
require_fixed docs/first-production-chat-migration-plan.md "Stage 5F-2 should be implementation-planning or inspection" "next stage"
require_fixed docs/first-production-chat-migration-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/first-production-chat-migration-plan.md "Do not:" "constraints present"
require_fixed docs/first-production-chat-migration-plan.md "change production chat behavior" "no chat behavior change"
require_fixed docs/first-production-chat-migration-plan.md "delete old databases" "no cleanup yet"

echo "PASS: first production chat migration plan markers are present"
