#!/usr/bin/env bash
set -euo pipefail

PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
DOC="docs/stage-17k-z-r12a-r3-profile-google-private-render-event-source.md"

test -f "$PANEL"
test -f "$DOC"

grep -Fq "PROFILE_GOOGLE_SYNC_PRIVATE_RENDER_EVENT_ONLY_R12A_R3" "$PANEL"
grep -Fq "function isPrivateProfileRenderEvent(event)" "$PANEL"
grep -Fq "detail.page === 'profile'" "$PANEL"
grep -Fq "detail.user" "$PANEL"
grep -Fq "function hasPrivateProfileShell()" "$PANEL"
grep -Fq ".private-shell[data-private-page=\"profile\"]" "$PANEL"
grep -Fq "function removePanel()" "$PANEL"
grep -Fq "function cleanupIfNotPrivateProfile()" "$PANEL"
grep -Fq "function renderPanel(event)" "$PANEL"
grep -Fq "function install(event)" "$PANEL"
grep -Fq "document.addEventListener('apc-private-page-rendered', install);" "$PANEL"
grep -Fq "document.addEventListener('apc-auth-changed', cleanupIfNotPrivateProfile);" "$PANEL"
grep -Fq "window.addEventListener('hashchange', cleanupIfNotPrivateProfile);" "$PANEL"
grep -Fq "window.addEventListener('popstate', cleanupIfNotPrivateProfile);" "$PANEL"
grep -Fq "Buddies Who Study local data" "$PANEL"

for bad in \
  "PROFILE_GOOGLE_SYNC_SIGNED_IN_PRIVATE_PROFILE_ONLY_R11Y_R2" \
  "function hasSignedInPrivateProfile()" \
  "privatePagesApi.me" \
  "root.APC_PRIVATEPAGES" \
  "document.addEventListener('DOMContentLoaded', install, { once: true });" \
  "window.addEventListener('hashchange', install);" \
  "window.addEventListener('popstate', install);" \
  "I understand APC will"; do
  if grep -Fq "$bad" "$PANEL"; then
    echo "FAIL forbidden content remains: $bad"
    exit 1
  fi
done

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
grep -Fq "Only one source file changed" "$DOC"
grep -Fq "apc-private-page-rendered" "$DOC"
grep -Fq "detail.page === \"profile\"" "$DOC"
grep -Fq "detail.user exists" "$DOC"
grep -Fq "does not create a second Profile page" "$DOC"
grep -Fq "does not add another auth layer" "$DOC"
grep -Fq "does not change routing" "$DOC"

echo "PASS stage-17k-z-r12a-r3 Profile Google private render event source smoke"
