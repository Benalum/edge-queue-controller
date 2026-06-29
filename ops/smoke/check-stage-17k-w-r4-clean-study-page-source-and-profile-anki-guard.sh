#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
SELECTOR="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js"
MANIFEST="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
DOC="$ROOT/docs/stage-17k-w-r4-clean-study-page-source-and-profile-anki-guard.md"

test -f "$INDEX"
test -f "$SELECTOR"
test -f "$MANIFEST"
test -f "$DOC"

grep -Fq "stage17kwr4-study-source-panel-removed-20260629" "$INDEX"
grep -Fq "stage17kwr4-anki-manifest-profile-only-20260629" "$INDEX"
grep -Fq "stage17kwr4-study-source-panel-removed-20260629" "$SELECTOR"
grep -Fq "stage17kwr4-anki-manifest-profile-only-20260629" "$MANIFEST"

grep -Fq "function removePanel()" "$SELECTOR"
grep -Fq "study_page_source_panel_enabled: false" "$SELECTOR"
grep -Fq "mydecks_source_picker_on_study_enabled: false" "$SELECTOR"
grep -Fq "external_file_ui_on_study_allowed: false" "$SELECTOR"

for forbidden in \
  "Study source" \
  "Study uses APC-native MyDecks on this page" \
  "No native study source selected yet" \
  "Study with MyDecks" \
  "Use MyDecks" \
  "Privacy and permission boundary" \
  "Clear source selection" \
  "Study with Anki" \
  "Anki file picker" \
  "Local Anki decks"
do
  if grep -Fq "$forbidden" "$SELECTOR"; then
    echo "forbidden Study selector UI marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "function isProfileRoute()" "$MANIFEST"
grep -Fq "function removeManifestPanel()" "$MANIFEST"
grep -Fq 'if (!isProfileRoute()) { removeManifestPanel(); return; }' "$MANIFEST"
grep -Fq "#profilePrivateApp" "$MANIFEST"

for forbidden in \
  'document.querySelector(".profile-card' \
  'routeText.indexOf("study")' \
  "routeText.indexOf('study')" \
  "[data-page='study']" \
  '[data-page="study"]' \
  ".sol-study-box" \
  "#apc-study-source-selector"
do
  if grep -Fq "$forbidden" "$MANIFEST"; then
    echo "forbidden Anki manifest route/mount marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "Clean Study Page Source and Profile Anki Guard" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$SELECTOR"
  node --check "$MANIFEST"
fi

echo "PASS: Stage 17K-W-R4 clean Study page source and Profile Anki guard smoke passed"
