#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== chat assistant message idempotency schema plan static check ==="

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

require_file docs/chat-assistant-message-idempotency-schema-plan.md
require_file docs/chat-only-migration-map.md
require_file docs/first-production-chat-migration-plan.md
require_file docs/laptop-queue-idempotent-completion.md
require_file docs/laptop-owned-data-plan.md

require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "planning only" "planning only"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "No schema changes happen in this stage." "no schema changes"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "No production chat behavior changes happen in this stage." "no production chat changes"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "add source_job_id to app_messages" "source_job_id recommendation"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "unique index on app_messages.source_job_id" "unique index recommendation"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "CREATE UNIQUE INDEX IF NOT EXISTS idx_app_messages_source_job_id_unique" "future index"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "verify job.status = complete" "complete-only persistence"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "verify job.result_json.reply is non-empty" "reply required"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "verify job.user_id matches authenticated user" "user ownership"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "insert assistant app_messages row with source_job_id = job.id" "assistant insert rule"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "never create assistant message for failed jobs" "failed no assistant"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "return the existing assistant message" "duplicate returns existing"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "Stage 5F-4 should implement the laptop Postgres schema migration" "next stage"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "Do not:" "constraints present"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "change schemas" "no schema implementation"
require_fixed docs/chat-assistant-message-idempotency-schema-plan.md "persist assistant messages from real jobs" "no real persistence"

echo "PASS: chat assistant message idempotency schema plan markers are present"
