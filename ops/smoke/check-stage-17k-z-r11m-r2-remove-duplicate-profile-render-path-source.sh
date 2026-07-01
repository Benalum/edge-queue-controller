#!/usr/bin/env bash
set -euo pipefail

INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PRIVATEPAGES="frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js"
PROFILE_HTML="frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html"
ANKI_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
GOOGLE_PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
PREVIEW_MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js"
DOC="docs/stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source.md"

test -f "$INDEX"
test -f "$PRIVATEPAGES"
test -f "$PROFILE_HTML"
test -f "$ANKI_PANEL"
test -f "$GOOGLE_PANEL"
test -f "$PREVIEW_MOUNT"
test -f "$DOC"

grep -q "data-apc-profile-root" "$PROFILE_HTML"
grep -q "data-page=\"profile\"" "$PROFILE_HTML"
grep -q "data-route=\"profile\"" "$PROFILE_HTML"
grep -q "data-apc-profile-google-sync-host" "$PROFILE_HTML"
grep -q "data-apc-profile-anki-manifest-host" "$PROFILE_HTML"
grep -q "data-apc-profile-anki-preview-host" "$PROFILE_HTML"

grep -q 'data-private-page="${escapeHtml(page)}" data-page="${escapeHtml(page)}" data-route="${escapeHtml(path)}"' "$PRIVATEPAGES"
grep -q "apc-private-page-rendered" "$PRIVATEPAGES"

grep -q "R11M-R2 removed legacy Google sync Profile loader from Anki panel" "$ANKI_PANEL"
grep -q "data-apc-profile-anki-manifest-host" "$ANKI_PANEL"

if grep -q "APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_START" "$ANKI_PANEL"; then
  echo "FAIL: stale Google sync loader start marker remains in Anki panel"
  exit 1
fi

if grep -q "APC_GOOGLE_SYNC_PROFILE_ONLY_STAGE_17K_Z_R6_END" "$ANKI_PANEL"; then
  echo "FAIL: stale Google sync loader end marker remains in Anki panel"
  exit 1
fi

if grep -q "apc:privatepage:rendered" "$ANKI_PANEL" "$GOOGLE_PANEL" "$PREVIEW_MOUNT"; then
  echo "FAIL: stale colon private-page event remains"
  exit 1
fi

grep -q "apc-private-page-rendered" "$GOOGLE_PANEL"
grep -q "data-apc-profile-google-sync-host" "$GOOGLE_PANEL"
grep -q "apc-private-page-rendered" "$PREVIEW_MOUNT"
grep -q "data-route=\"profile\"" "$PREVIEW_MOUNT"

grep -q "/privatepages/profile-google-sync-panel.js?v=stage17k-z-r11m-r2-canonical-profile-source-20260701" "$INDEX"
grep -q "/privatepages/privatepages.js?v=stage17k-z-r11m-r2-canonical-profile-source-20260701" "$INDEX"
grep -q "/privatepages/anki-manifest-panel.js?v=stage17k-z-r11m-r2-canonical-profile-source-20260701" "$INDEX"
grep -q "/privatepages/profile-anki-preview-mount.js?v=stage17k-z-r11m-r2-canonical-profile-source-20260701" "$INDEX"

if command -v node >/dev/null 2>&1; then
  node --check "$PRIVATEPAGES"
  node --check "$ANKI_PANEL"
  node --check "$GOOGLE_PANEL"
  node --check "$PREVIEW_MOUNT"
fi

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"
grep -q "removes the duplicate loader path" "$DOC"

echo "PASS stage-17k-z-r11m-r2 remove duplicate Profile render path source smoke"
