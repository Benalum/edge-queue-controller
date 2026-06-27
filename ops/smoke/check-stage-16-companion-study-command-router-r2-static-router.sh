#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIRROR="$REPO/frontend/wrapper-ui/apc-wrapper-local"
COMPANION="$MIRROR/privatepages/companion.js"
INDEX="$MIRROR/index.html"

test -f "$COMPANION"
test -f "$INDEX"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
fi

grep -q "Companion Study Command Router R2" "$COMPANION"
grep -q "function routeStudyCommand" "$COMPANION"
grep -q "function commandStartStudy" "$COMPANION"
grep -q "function commandPauseStudy" "$COMPANION"
grep -q "function commandResumeStudy" "$COMPANION"
grep -q "function commandStopStudy" "$COMPANION"
grep -q "function commandCreateCardStart" "$COMPANION"
grep -q "function commandDeleteCardStart" "$COMPANION"
grep -q "function commandEditCardStart" "$COMPANION"
grep -q "const routed = routeStudyCommand(clean);" "$COMPANION"

grep -q "study-command-router-r2-20260627" "$INDEX"

echo "companion study command router R2 static smoke PASS"
