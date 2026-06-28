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

grep -q "Companion Browser Voice R3D" "$COMPANION"
grep -q "function getBrowserVoices" "$COMPANION"
grep -q "function renderBrowserVoiceOptions" "$COMPANION"
grep -q "companionBrowserVoiceSelect" "$COMPANION"
grep -q "speechSynthesis.getVoices" "$COMPANION"
grep -q "browser-voice-r3d-20260627" "$INDEX"

! grep -q "Auto-listen after Sol speaks" "$COMPANION"
! grep -q "Kokoro fallback voice" "$COMPANION"
! grep -q "Kokoro voice" "$COMPANION"
! grep -q "Sol will speak with your browser first" "$COMPANION"

echo "companion browser voice R3D simplified UI smoke PASS"
