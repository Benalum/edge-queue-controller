#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== frontend queued chat config flag smoke ==="

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

require_file frontend/wrapper-ui/queued_chat_config.js
require_file frontend/wrapper-ui/queued_chat_status.js
require_file frontend/wrapper-ui/index.html
require_file frontend/wrapper-ui/app.js
require_file docs/frontend-queued-chat-config-flag.md
require_file docs/frontend-queued-chat-helper-import.md

require_fixed frontend/wrapper-ui/queued_chat_config.js "Stage 5F-30" "stage marker"
require_fixed frontend/wrapper-ui/queued_chat_config.js "enabled: false" "default off"
require_fixed frontend/wrapper-ui/queued_chat_config.js "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "global default false"
require_fixed frontend/wrapper-ui/queued_chat_config.js "does not call /api/chat/queued" "no queued API call"
require_fixed frontend/wrapper-ui/index.html "queued_chat_config.js" "index imports config"
require_fixed frontend/wrapper-ui/index.html "queued_chat_status.js" "index imports helper"
require_fixed docs/frontend-queued-chat-config-flag.md "window.AI_PLATFORM_QUEUED_CHAT_ENABLED === false" "documented default off"
require_fixed docs/frontend-queued-chat-config-flag.md "app.js still does not call /api/chat/queued" "app no queued API"
require_fixed docs/frontend-queued-chat-config-flag.md "Stage 5F-31 should add a disabled-by-default app.js detection path" "next stage"

config_line="$(grep -n "queued_chat_config.js" frontend/wrapper-ui/index.html | head -1 | cut -d: -f1)"
status_line="$(grep -n "queued_chat_status.js" frontend/wrapper-ui/index.html | head -1 | cut -d: -f1)"

if [ -z "$config_line" ] || [ -z "$status_line" ]; then
  echo "FAIL: could not determine script order"
  exit 1
fi

if [ "$config_line" -gt "$status_line" ]; then
  echo "FAIL: queued_chat_config.js should load before queued_chat_status.js"
  exit 1
fi

echo "OK: queued_chat_config.js loads before queued_chat_status.js"

if grep -F -n "/api/chat/queued" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not call /api/chat/queued yet"
  exit 1
fi

echo "OK: app.js does not call /api/chat/queued"

if grep -F -n "Stage 5F-31: queued-chat frontend flag detection." frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  require_fixed frontend/wrapper-ui/app.js "AI_PLATFORM_QUEUED_CHAT_ENABLED === true" "app reads queued flag after Stage 5F-31"
  require_fixed frontend/wrapper-ui/app.js "queuedSendWired: false" "queued send still not wired"
else
  if grep -F -n "AI_PLATFORM_QUEUED_CHAT_ENABLED" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
    echo "FAIL: app.js should not read queued chat flag before Stage 5F-31"
    exit 1
  fi
  echo "OK: app.js does not read queued chat flag yet"
fi

if grep -F -n "QueuedChatStatusHelper" frontend/wrapper-ui/app.js >/dev/null 2>&1; then
  echo "FAIL: app.js should not use QueuedChatStatusHelper yet"
  exit 1
fi

echo "OK: app.js does not use QueuedChatStatusHelper yet"

if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/queued_chat_config.js
  node --check frontend/wrapper-ui/queued_chat_status.js

  node - <<'NODE'
const config = require("./frontend/wrapper-ui/queued_chat_config.js");

if (config.enabled !== false) {
  throw new Error("queued chat config should default disabled: " + JSON.stringify(config));
}

if (config.timeoutMs !== 120000) {
  throw new Error("queued chat timeout config mismatch: " + JSON.stringify(config));
}

console.log("OK: queued chat config defaults disabled");
NODE
else
  echo "OK: node unavailable; static checks only"
fi

echo "PASS: frontend queued chat config flag smoke passed"
