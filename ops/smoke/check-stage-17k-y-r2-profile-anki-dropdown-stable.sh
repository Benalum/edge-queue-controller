#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
MANIFEST="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
DOC="$ROOT/docs/stage-17k-y-r2-profile-anki-dropdown-stable.md"

test -f "$INDEX"
test -f "$MANIFEST"
test -f "$DOC"

grep -Fq "stage17kyr2-profile-anki-dropdown-stable-20260629" "$INDEX"
grep -Fq "stage17kyr2-profile-anki-dropdown-stable-20260629" "$MANIFEST"
grep -Fq "Where is my Anki file?" "$MANIFEST"
grep -Fq "apc-anki-file-location-help[open]" "$MANIFEST"
grep -Fq "ankiFileHelpWasOpen" "$MANIFEST"
grep -Fq "Deck card counts" "$MANIFEST"

for forbidden in \
  'document.addEventListener("click"' \
  "Selected file proof" \
  "Sample SHA-256" \
  "Local note type details" \
  "Clear local Anki proof" \
  'document.querySelector(".profile-card'
do
  if grep -Fq "$forbidden" "$MANIFEST"; then
    echo "forbidden/noisy Profile Anki marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "Profile Anki Dropdown Stable" "$DOC"
grep -Fq "remounted the panel on every document click" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$MANIFEST"
fi

echo "PASS: Stage 17K-Y-R2 Profile Anki dropdown stable smoke passed"
