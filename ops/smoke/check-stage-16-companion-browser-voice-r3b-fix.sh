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

grep -q "Companion Browser Voice R3B" "$COMPANION"
grep -q "function browserSpeechSupported" "$COMPANION"
grep -q "function speakWithBrowser" "$COMPANION"
grep -q "function enableVoice" "$COMPANION"
grep -q "function disableVoice" "$COMPANION"
grep -q "async function speakText" "$COMPANION"
grep -q 'data-companion-action="enable-voice"' "$COMPANION"
grep -q 'data-companion-action="disable-voice"' "$COMPANION"
grep -q "browser-voice-r3b-20260627" "$INDEX"

echo "companion browser voice R3B smoke PASS"
