#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== single frontend owner plan static check ==="

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

require_file docs/single-frontend-owner-plan.md
require_file frontend/wrapper-ui/app.js
require_file frontend/wrapper-ui/dev_server.py
require_file frontend/wrapper-ui/index.html

require_fixed docs/single-frontend-owner-plan.md "The laptop/controller public wrapper should own all user-facing tabs" "wrapper owns all user-facing tabs"
require_fixed docs/single-frontend-owner-plan.md "CT101 should remain the backend/API/job/model server." "CT101 backend role"
require_fixed docs/single-frontend-owner-plan.md "All visible tabs should load from the laptop/controller wrapper" "all visible tabs wrapper-owned"
require_fixed docs/single-frontend-owner-plan.md "Logged-out protected tabs should show a login prompt" "logged-out behavior"
require_fixed docs/single-frontend-owner-plan.md "If CT101 is offline, the wrapper tab should still load" "offline behavior"
require_fixed docs/single-frontend-owner-plan.md "/companion should route to the unified Chat tab in Companion mode" "companion compatibility"
require_fixed docs/single-frontend-owner-plan.md "/chats should not silently look like the homepage" "chats route compatibility"
require_fixed docs/single-frontend-owner-plan.md "Do not proxy protected routes to CT101 frontend automatically." "future no auto proxy plan"
require_fixed docs/single-frontend-owner-plan.md "No runtime route changes." "Stage 5A no runtime changes"

echo "PASS: single frontend owner plan markers are present"
