#!/usr/bin/env bash
set -euo pipefail

ANKI="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
DOC="docs/stage-17k-z-r12h-r2-anki-private-profile-event-source.md"

test -f "$ANKI"
test -f "$DOC"

grep -Fq "APC_ANKI_MANIFEST_PRIVATE_PROFILE_EVENT_ONLY_R12H_R2" "$ANKI"
grep -Fq "function isPrivateProfileRenderEvent(event)" "$ANKI"
grep -Fq 'detail.page === "profile"' "$ANKI"
grep -Fq "detail.user" "$ANKI"
grep -Fq "function hasPrivateProfileShell()" "$ANKI"
grep -Fq ".private-shell[data-private-page='profile']" "$ANKI"
grep -Fq "function cleanupIfNotPrivateProfile()" "$ANKI"
grep -Fq "function isProfileRoute()" "$ANKI"
grep -Fq "return hasPrivateProfileShell();" "$ANKI"
grep -Fq "function findMountHost()" "$ANKI"
grep -Fq "function scheduleMount(event)" "$ANKI"
grep -Fq "if (!isPrivateProfileRenderEvent(event))" "$ANKI"
grep -Fq 'window.addEventListener("DOMContentLoaded", cleanupIfNotPrivateProfile);' "$ANKI"
grep -Fq 'window.addEventListener("popstate", cleanupIfNotPrivateProfile);' "$ANKI"
grep -Fq 'window.addEventListener("hashchange", cleanupIfNotPrivateProfile);' "$ANKI"
grep -Fq 'document.addEventListener("apc-auth-changed", cleanupIfNotPrivateProfile);' "$ANKI"
grep -Fq 'document.addEventListener("apc-private-page-rendered", scheduleMount);' "$ANKI"
grep -Fq "Buddies Who Study reads deck names and card counts locally in this browser." "$ANKI"

for bad in \
  'window.addEventListener("DOMContentLoaded", scheduleMount);' \
  'window.addEventListener("popstate", scheduleMount);' \
  'window.addEventListener("hashchange", scheduleMount);' \
  'document.addEventListener("apc-private-page-rendered", function ()' \
  'if (!isProfileRoute()) { removeManifestPanel(); return; }' \
  'document.querySelector("[data-page=' \
  'document.querySelector(".profile-grid")' \
  'document.querySelector(".private-profile-grid")' \
  'document.querySelector("main")' \
  '|| document.body' \
  'APC reads deck names and card counts locally in this browser.'; do
  if grep -Fq "$bad" "$ANKI"; then
    echo "FAIL forbidden Anki mount/copy content remains: $bad"
    exit 1
  fi
done

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/index.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js; then
  echo "FAIL: forbidden broad/Profile/Google/local-backups/APKG files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/index.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$ANKI"
fi

grep -Fq "Source-only narrow fix" "$DOC"
grep -Fq "No deploy" "$DOC"
grep -Fq "mounts only from the private Profile render event" "$DOC"
grep -Fq 'detail.page === "profile"' "$DOC"
grep -Fq "detail.user" "$DOC"
grep -Fq "Only one existing source file changed" "$DOC"
grep -Fq "no Anki chooser flash" "$DOC"

echo "PASS stage-17k-z-r12h-r2 Anki private Profile event source smoke"
