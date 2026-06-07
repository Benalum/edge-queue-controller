#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== public unified chat route static check ==="

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

require_fixed frontend/wrapper-ui/index.html 'href="/chat" data-route="/chat">Chat</a>' "public nav Chat link"
require_fixed frontend/wrapper-ui/app.js '"/chat": {' "public /chat summary page"
require_fixed frontend/wrapper-ui/app.js 'PRIVATE_APP_ROUTE_SET = new Set(["/study", "/chat", "/companion", "/profile"])' "auth refresh includes /chat"
require_fixed frontend/wrapper-ui/dev_server.py 'FULL_APP_ROUTES = {"/study", "/chat", "/companion", "/calendar", "/profile"}' "dev server proxies /chat when authenticated"
require_fixed frontend/wrapper-ui/dev_server.py 'WRAPPER_ROUTES = {"/", "/study", "/chat", "/companion", "/calendar", "/profile", "/system"}' "wrapper routes include /chat"

echo "PASS: public unified chat route markers are present"
