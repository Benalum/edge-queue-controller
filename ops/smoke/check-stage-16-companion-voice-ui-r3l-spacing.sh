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

grep -q "Companion Voice UI R3L" "$COMPANION"
grep -q "sol-voice-toggle-actions" "$COMPANION"
grep -q "sol-browser-voice-row" "$COMPANION"
grep -q "Browser voice" "$COMPANION"
grep -q "companionBrowserVoiceSelect" "$COMPANION"
grep -q "voice-ui-r3l-spacing-20260627" "$INDEX"

echo "companion voice UI R3L spacing smoke PASS"
