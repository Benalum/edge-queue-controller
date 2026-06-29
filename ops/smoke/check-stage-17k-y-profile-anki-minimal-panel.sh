#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
MANIFEST="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
DOC="$ROOT/docs/stage-17k-y-profile-anki-minimal-panel.md"

test -f "$INDEX"
test -f "$MANIFEST"
test -f "$DOC"

grep -Fq "stage17ky-profile-anki-minimal-panel-20260629" "$INDEX"
grep -Fq "stage17ky-profile-anki-minimal-panel-20260629" "$MANIFEST"

grep -Fq "function renderAnkiFileHelpHtml()" "$MANIFEST"
grep -Fq "function renderMinimalDeckSummaryHtml()" "$MANIFEST"
grep -Fq "function renderPanelHtml(message)" "$MANIFEST"
grep -Fq "Where is my Anki file?" "$MANIFEST"
grep -Fq "Choose Anki file" "$MANIFEST"
grep -Fq "Deck card counts" "$MANIFEST"
grep -Fq "%APPDATA%\\\\Anki2" "$MANIFEST"
grep -Fq "~/Library/Application Support/Anki2" "$MANIFEST"
grep -Fq "~/.local/share/Anki2" "$MANIFEST"
grep -Fq "AnkiDroid Settings" "$MANIFEST"
grep -Fq "iPhone / iPad" "$MANIFEST"
grep -Fq 'if (!isProfileRoute()) { removeManifestPanel(); return; }' "$MANIFEST"

for forbidden in \
  "Data ownership update" \
  "Anki files stay local to your browser" \
  "Selected file proof" \
  "File status" \
  "Sample SHA-256" \
  "Local note type details" \
  "Note types with notes" \
  "Source type" \
  "Clear local Anki proof" \
  'document.querySelector(".profile-card'
do
  if grep -Fq "$forbidden" "$MANIFEST"; then
    echo "forbidden noisy Profile Anki marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "Profile Anki Minimal Panel" "$DOC"
grep -Fq "Where is my Anki file?" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$MANIFEST"
fi

echo "PASS: Stage 17K-Y Profile Anki minimal panel smoke passed"
