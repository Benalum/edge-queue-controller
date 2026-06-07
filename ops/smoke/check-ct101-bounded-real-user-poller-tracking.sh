#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 bounded real-user poller tracking smoke ==="

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

require_file docs/ct101-bounded-real-user-poller-tracking.md
require_file docs/ct101-real-user-execution-guard-tracking.md
require_file docs/real-user-ct101-queue-execution-guard-plan.md

require_fixed docs/ct101-bounded-real-user-poller-tracking.md "LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1" "real-user jobs flag"
require_fixed docs/ct101-bounded-real-user-poller-tracking.md "Synthetic-only mode remains supported." "synthetic unchanged"
require_fixed docs/ct101-bounded-real-user-poller-tracking.md "Persistent workers are still not enabled." "no persistent workers"
require_fixed docs/ct101-bounded-real-user-poller-tracking.md "ai-platform-stage-5f23-bounded-real-user-poller-guard-2026-06-07" "CT101 tag"
require_fixed docs/ct101-bounded-real-user-poller-tracking.md "Stage 5F-24 should add a controller-side real-user route-to-CT101 bounded lifecycle smoke." "next stage"

echo "PASS: CT101 bounded real-user poller tracking markers are present"
