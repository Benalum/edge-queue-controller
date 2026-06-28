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

grep -q "Companion Browser-Only Voice R3M" "$COMPANION"
grep -q "function applyBrowserOnlyVoiceDefaultsR3M" "$COMPANION"
grep -q "Voice and listening use your browser only" "$COMPANION"
grep -q "Google Chrome has been tested and verified" "$COMPANION"
grep -q "sol-browser-voice-row" "$COMPANION"
grep -q "browser-only-voice-r3m-20260627" "$INDEX"

if grep -q 'settings.voiceProvider = "kokoro"' "$COMPANION"; then
  echo "Kokoro provider assignment still present"
  exit 1
fi

if grep -q 'await speakWithKokoro(clean, settings)' "$COMPANION"; then
  echo "Kokoro speak fallback call still present"
  exit 1
fi

echo "companion browser-only voice R3M smoke PASS"
