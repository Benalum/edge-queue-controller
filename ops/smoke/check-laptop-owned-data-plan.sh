#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop-owned data architecture plan static check ==="

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

require_file docs/laptop-owned-data-plan.md
require_file docs/single-frontend-owner-plan.md

require_fixed docs/laptop-owned-data-plan.md "The laptop/controller becomes the source of truth for user-facing data." "laptop source of truth"
require_fixed docs/laptop-owned-data-plan.md "CT101 becomes a worker/model execution node." "CT101 worker/model role"
require_fixed docs/laptop-owned-data-plan.md "Users can log in, view saved data, create data, and queue work even when CT101 is offline." "offline user capability"
require_fixed docs/laptop-owned-data-plan.md "Use Postgres on the laptop/controller as the long-term app database." "Postgres recommendation"
require_fixed docs/laptop-owned-data-plan.md "Worker claims a queued job from laptop/controller." "worker claim protocol"
require_fixed docs/laptop-owned-data-plan.md "jobs remain queued" "offline queue behavior"
require_fixed docs/laptop-owned-data-plan.md "daily Postgres dump" "backup requirement"
require_fixed docs/laptop-owned-data-plan.md "Inspect current CT101 schema and define a table-by-table migration map." "next migration map stage"
require_fixed docs/laptop-owned-data-plan.md "Do not:" "no implementation yet"
require_fixed docs/laptop-owned-data-plan.md "move production data yet" "no data migration yet"
require_fixed docs/single-frontend-owner-plan.md "CT101 should remain the backend/API/job/model server." "Stage 5A alignment"

echo "PASS: laptop-owned data architecture plan markers are present"
