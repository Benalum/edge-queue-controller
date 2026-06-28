#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPANION="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
INDEX="$REPO/frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$COMPANION"
test -f "$INDEX"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
fi

grep -q "Companion Listen UI R3H" "$COMPANION"
grep -q "function conversationSilenceSeconds" "$COMPANION"
grep -q "function updateConversationSilenceSeconds" "$COMPANION"
grep -q "companionSilenceSeconds" "$COMPANION"
grep -q "Silence before sending" "$COMPANION"
grep -q 'data-companion-action="conversation-start"' "$COMPANION"
grep -q 'data-companion-action="conversation-stop"' "$COMPANION"
grep -q "listen-ui-r3h-20260627" "$INDEX"

if grep -q 'data-companion-action="listen-auto-send" .*Listen and auto-send' "$COMPANION"; then
  echo "manual Listen and auto-send button still present"
  exit 1
fi

if grep -q 'data-companion-action="stop-listening" .*Stop listening' "$COMPANION"; then
  echo "manual Stop listening button still present"
  exit 1
fi

echo "companion listen UI R3H silence setting smoke PASS"
