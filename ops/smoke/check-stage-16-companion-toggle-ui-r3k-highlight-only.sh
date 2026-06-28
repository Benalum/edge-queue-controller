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

grep -q "Companion Toggle UI R3K" "$COMPANION"
grep -q "function applyPassiveInteractionDefaultsR3K" "$COMPANION"
grep -q "aria-pressed" "$COMPANION"
grep -q "const enableClass = voiceOn" "$COMPANION"
grep -q "const startClass = conversationOn" "$COMPANION"
grep -q "toggle-ui-r3k-highlight-only-20260627" "$INDEX"

for phrase in "Voice enabled." "Voice disabled." "Conversation mode started." "Conversation mode stopped."; do
  if grep -q "$phrase" "$COMPANION"; then
    echo "toggle chat phrase still present: $phrase"
    exit 1
  fi
done

echo "companion toggle UI R3K highlight-only smoke PASS"
