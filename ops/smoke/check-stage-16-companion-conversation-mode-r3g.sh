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

grep -q "Companion Conversation Mode R3G" "$COMPANION"
grep -q "function startConversationMode" "$COMPANION"
grep -q "function stopConversationMode" "$COMPANION"
grep -q "function maybeStartConversationListening" "$COMPANION"
grep -q 'data-companion-action="conversation-start"' "$COMPANION"
grep -q 'data-companion-action="conversation-stop"' "$COMPANION"
grep -q "conversationModeEnabled" "$COMPANION"
grep -q "conversation-mode-r3g-20260627" "$INDEX"

echo "companion conversation mode R3G smoke PASS"
