#!/usr/bin/env bash
set -euo pipefail

MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js"
DOC="docs/stage-17k-z-r11u-apkg-preview-mount-stable-profile-dom-source-only.md"

test -f "$MOUNT"
test -f "$DOC"

grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_R11G" "$MOUNT"
grep -q "APC_PROFILE_ANKI_PREVIEW_MOUNT_STABLE_PROFILE_DOM_R11U" "$MOUNT"
grep -q ".private-shell\\[data-private-page='profile'\\] .private-grid" "$MOUNT"
grep -q ".private-shell\\[data-private-page='profile'\\]" "$MOUNT"
grep -q "data-apc-profile-anki-preview-host" "$MOUNT"

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/index.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js; then
  echo "FAIL: forbidden broad/session/Profile/Google files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/index.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$MOUNT"
fi

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "Only one source file changed" "$DOC"
grep -q "This does not touch" "$DOC"
grep -q "does not add a new Profile shell" "$DOC"
grep -q "does not change routing" "$DOC"
grep -q "does not duplicate Profile rendering" "$DOC"

echo "PASS stage-17k-z-r11u APKG preview mount stable Profile DOM source-only smoke"
