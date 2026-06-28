#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPANION="$REPO/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
INDEX="$REPO/frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="$REPO/docs/stage-16-global-drive-banner-r3p.md"

test -f "$COMPANION"
test -f "$INDEX"
test -f "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$COMPANION"
fi

grep -q "Global Drive Banner R3P" "$INDEX"
grep -q "apc-global-drive-banner" "$INDEX"
grep -q "Data ownership update" "$INDEX"
grep -q "Google Drive sync" "$INDEX"
grep -q "Current storage remains on the existing platform" "$INDEX"
grep -q "global-drive-banner-r3p-20260627" "$INDEX"

if grep -q "renderDriveOwnershipBanner" "$COMPANION"; then
  echo "Companion-tab banner function still present"
  exit 1
fi

if grep -q "Data ownership notice" "$COMPANION"; then
  echo "Companion-tab banner copy still present"
  exit 1
fi

echo "global Drive banner R3P smoke PASS"
