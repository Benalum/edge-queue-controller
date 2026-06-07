#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== chat-only migration map static check ==="

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

require_file docs/chat-only-migration-inspection-notes.md
require_file docs/chat-only-migration-map.md
require_file docs/first-production-chat-migration-plan.md
require_file docs/laptop-owned-data-plan.md
require_file docs/ct101-to-laptop-migration-map.md
require_file docs/single-frontend-owner-plan.md

require_fixed docs/chat-only-migration-map.md "inspection and planning only" "planning only"
require_fixed docs/chat-only-migration-map.md "No production chat behavior changes happen in this stage." "no production changes"
require_fixed docs/chat-only-migration-map.md "normal chat" "normal chat target"
require_fixed docs/chat-only-migration-map.md "job type: ollama_chat" "ollama_chat target"
require_fixed docs/chat-only-migration-map.md "laptop/controller owns visible chat UI" "laptop UI owner"
require_fixed docs/chat-only-migration-map.md "CT101 executes model work and returns result_json" "CT101 executor"
require_fixed docs/chat-only-migration-map.md "Default must remain off." "feature default off"
require_fixed docs/chat-only-migration-map.md "The server must derive user_id from the session." "server-derived user id"
require_fixed docs/chat-only-migration-map.md "Do not include secrets" "no secrets payload"
require_fixed docs/chat-only-migration-map.md "create exactly one assistant message" "single assistant message"
require_fixed docs/chat-only-migration-map.md "A failed job must not create an assistant message." "failed no assistant"
require_fixed docs/chat-only-migration-map.md "A duplicate complete must not create duplicate assistant messages." "duplicate no assistant"
require_fixed docs/chat-only-migration-map.md "add source_job_id to app_messages" "source_job_id recommendation"
require_fixed docs/chat-only-migration-map.md "Do not add this schema change in Stage 5F-2." "no schema change"
require_fixed docs/chat-only-migration-map.md "Rollback should be" "rollback section"
require_fixed docs/chat-only-migration-map.md "CT101 offline queued state smoke" "offline smoke"
require_fixed docs/chat-only-migration-map.md "Stage 5F-3 should be schema planning" "next stage"
require_fixed docs/chat-only-migration-map.md "Cleanup must wait until laptop queue is production source of truth" "cleanup gated"
require_fixed docs/chat-only-migration-map.md "Do not:" "constraints present"
require_fixed docs/chat-only-migration-map.md "change production chat behavior" "no chat behavior change"
require_fixed docs/chat-only-migration-map.md "add schema changes" "no schema change constraint"

require_fixed docs/chat-only-migration-inspection-notes.md "Controller chat/session/API markers" "controller inspection"
require_fixed docs/chat-only-migration-inspection-notes.md "CT101 chat/session/job markers" "CT101 inspection"

echo "PASS: chat-only migration map markers are present"
