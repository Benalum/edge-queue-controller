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

grep -q "Companion Intro Copy R3N" "$COMPANION"
grep -q "You can talk with me, study flashcards, and manage your decks" "$COMPANION"
grep -q "select deck \[deck name\]" "$COMPANION"
grep -q "show current card" "$COMPANION"
grep -q "You can also create, edit, delete, and flag cards" "$COMPANION"
grep -q "companion-intro-copy-r3n-20260627" "$INDEX"

if grep -q "select deck mathmatic" "$COMPANION"; then
  echo "old deck-specific copy still present"
  exit 1
fi

echo "companion intro copy R3N smoke PASS"
