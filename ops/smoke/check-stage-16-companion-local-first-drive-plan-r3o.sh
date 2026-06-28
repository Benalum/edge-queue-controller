#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$REPO/docs/stage-16-companion-local-first-google-drive-storage-plan-r3o.md"
COMPANION="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
INDEX="$REPO/frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$DOC"
test -f "$COMPANION"
test -f "$INDEX"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
fi

grep -q "Local-First Google Drive Storage Plan R3O" "$DOC"
grep -q "Google Drive sync" "$DOC"
grep -q "IndexedDB cache" "$DOC"
grep -q "No backend changes" "$DOC"

grep -q "Companion Local-First Drive Notice R3O" "$COMPANION"
grep -q "function renderDriveOwnershipBanner" "$COMPANION"
grep -q "Data ownership notice" "$COMPANION"
grep -q "Google Drive sync" "$COMPANION"
grep -q "planned storage direction" "$COMPANION"
grep -q "local-first-drive-plan-r3o-20260627" "$INDEX"

echo "companion local-first Drive plan R3O smoke PASS"
