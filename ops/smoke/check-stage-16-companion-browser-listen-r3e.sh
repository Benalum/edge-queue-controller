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

grep -q "Companion Browser Listen R3E" "$COMPANION"
grep -q "function browserRecognitionSupported" "$COMPANION"
grep -q "function startBrowserListening" "$COMPANION"
grep -q "function stopBrowserListening" "$COMPANION"
grep -q "function renderListenBox" "$COMPANION"
grep -q 'data-companion-action="listen-auto-send"' "$COMPANION"
grep -q 'data-companion-action="listen-draft"' "$COMPANION"
grep -q 'data-companion-action="stop-listening"' "$COMPANION"
grep -q "browser-listen-r3e-20260627" "$INDEX"

echo "companion browser listen R3E smoke PASS"
