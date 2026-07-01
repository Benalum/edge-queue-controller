#!/usr/bin/env bash
set -euo pipefail

PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
DOC="docs/stage-17k-z-r11y-profile-google-sync-signed-in-private-only-source.md"

test -f "$PANEL"
test -f "$DOC"

grep -Fq "PROFILE_GOOGLE_SYNC_SIGNED_IN_PRIVATE_PROFILE_ONLY_R11Y" "$PANEL"
grep -Fq "function hasSignedInPrivateProfile()" "$PANEL"
grep -Fq ".private-shell[data-private-page=\"profile\"]" "$PANEL"
grep -Fq "root.APC_PRIVATEPAGES" "$PANEL"
grep -Fq "privatePagesApi.me" "$PANEL"
grep -Fq "function removePanel()" "$PANEL"
grep -Fq "!hasSignedInPrivateProfile()" "$PANEL"
grep -Fq "document.addEventListener('apc-auth-changed', install);" "$PANEL"
grep -Fq "document.addEventListener('apc-private-page-rendered', install);" "$PANEL"
grep -Fq "Buddies Who Study local data" "$PANEL"

if grep -Fq "I understand APC will" "$PANEL"; then
  echo "FAIL: old APC consent copy returned"
  exit 1
fi

if grep -Fq "Create hidden APC sync database" "$PANEL"; then
  echo "FAIL: old APC sync database copy returned"
  exit 1
fi

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/index.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js; then
  echo "FAIL: forbidden broad/Profile/Anki files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/index.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$PANEL"
fi

grep -Fq "No deploy" "$DOC"
grep -Fq "No frontend live mutation" "$DOC"
grep -Fq "No backend route addition" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "Only one source file changed" "$DOC"
grep -Fq "signed-in private Profile" "$DOC"
grep -Fq "This does not touch" "$DOC"
grep -Fq "does not add another Profile shell" "$DOC"
grep -Fq "does not change routing" "$DOC"
grep -Fq "does not duplicate rendering" "$DOC"

echo "PASS stage-17k-z-r11y Profile Google sync signed-in private-only source smoke"
