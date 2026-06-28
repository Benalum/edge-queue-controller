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

grep -q "Companion Browser Listen R3F" "$COMPANION"
grep -q "function restorePromptAfterRender" "$COMPANION"
grep -q "function submitListenedPrompt" "$COMPANION"
grep -q "capturedText" "$COMPANION"
grep -q "function stopBrowserListening" "$COMPANION"
grep -q "preservedPromptText" "$COMPANION"
grep -q "browser-listen-r3f-20260627" "$INDEX"

echo "companion browser listen R3F preserve submit smoke PASS"
