#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== CT101 dormant laptop queue client tracking smoke ==="

CT_SSH="${CT101_HOST_SSH:-root@100.88.194.19}"
CT_ID="${CT101_ID:-101}"

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
    exit 1
  fi
}

require_file docs/ct101-dormant-laptop-queue-client-tracking.md
require_fixed docs/ct101-dormant-laptop-queue-client-tracking.md "not wired into the production CT101 worker loop yet" "not wired into production worker"
require_fixed docs/ct101-dormant-laptop-queue-client-tracking.md "Synthetic-only mode refuses non-synthetic job IDs." "synthetic safety"

ssh "$CT_SSH" "pct exec $CT_ID -- bash -lc '
cd /opt/ai-platform
python3 -m py_compile backend/app/worker/laptop_queue_client.py
bash ops/smoke/check-laptop-queue-client-dormant.sh
git status --short --branch
'"

echo "PASS: CT101 dormant laptop queue client tracking smoke passed"
