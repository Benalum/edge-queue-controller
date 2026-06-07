#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 to laptop migration map static check ==="

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

require_file docs/ct101-to-laptop-migration-map.md
require_file docs/laptop-owned-data-plan.md
require_file docs/single-frontend-owner-plan.md

for table in \
  users \
  user_sessions \
  chats \
  messages \
  companion_study_sessions \
  workers \
  jobs \
  user_profiles \
  companion_profiles \
  worker_nodes \
  study_decks \
  study_cards \
  study_reviews \
  calendar_events
do
  require_fixed docs/ct101-to-laptop-migration-map.md "$table" "CT101 table mapped: $table"
done

for table in \
  power_idle_state \
  power_events \
  power_auto_state \
  worker_events
do
  require_fixed docs/ct101-to-laptop-migration-map.md "$table" "controller/runtime table mapped: $table"
done

require_fixed docs/ct101-to-laptop-migration-map.md "Laptop/controller becomes the source of truth for user-facing data." "future source of truth"
require_fixed docs/ct101-to-laptop-migration-map.md "CT101 becomes a worker/model execution node." "CT101 worker/model target"
require_fixed docs/ct101-to-laptop-migration-map.md "only one system may be source of truth for a table" "single source of truth cutover rule"
require_fixed docs/ct101-to-laptop-migration-map.md "do not run dual writes without idempotency" "dual write safety rule"
require_fixed docs/ct101-to-laptop-migration-map.md "Move chat/chats/messages first." "chat first migration phase"
require_fixed docs/ct101-to-laptop-migration-map.md "Do not:" "Stage 5C no implementation"
require_fixed docs/ct101-to-laptop-migration-map.md "migrate production data" "no data migration"

echo "PASS: CT101 to laptop migration map markers are present"
