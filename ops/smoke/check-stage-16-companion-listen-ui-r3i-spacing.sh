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

grep -q "Companion Listen UI R3I" "$COMPANION"
grep -q "sol-listen-actions" "$COMPANION"
grep -q "sol-listen-delay-row" "$COMPANION"
grep -q "Silence before sending" "$COMPANION"
grep -q "listen-ui-r3i-spacing-20260627" "$INDEX"

echo "companion listen UI R3I spacing smoke PASS"
