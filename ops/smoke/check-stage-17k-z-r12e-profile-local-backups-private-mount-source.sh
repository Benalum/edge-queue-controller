#!/usr/bin/env bash
set -euo pipefail

MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-z-r12e-profile-local-backups-private-mount-source.md"

test -f "$MOUNT"
test -f "$PANEL"
test -f "$DOC"

grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY" "$MOUNT"
grep -Fq "function isPrivateProfileRenderEvent(event)" "$MOUNT"
grep -Fq "detail.page === \"profile\"" "$MOUNT"
grep -Fq "detail.user" "$MOUNT"
grep -Fq "function findMountHost()" "$MOUNT"
grep -Fq ".private-shell[data-private-page=\"profile\"] .private-grid" "$MOUNT"
grep -Fq "function mountFromPrivateProfileEvent(event)" "$MOUNT"
grep -Fq "document.addEventListener(\"apc-private-page-rendered\", mountFromPrivateProfileEvent)" "$MOUNT"
grep -Fq "document.addEventListener(\"apc-auth-changed\", cleanupIfNotPrivateProfile)" "$MOUNT"
grep -Fq "chooseFolderAndWriteBackup" "$MOUNT"
grep -Fq "buildBackupPayload" "$MOUNT"
grep -Fq "createDownloadUrl" "$MOUNT"
grep -Fq "Backup download started." "$MOUNT"
grep -Fq "uploadsToServer: false" "$MOUNT"
grep -Fq "root.APC_PROFILE_LOCAL_BACKUPS_MOUNT = mountApi" "$MOUNT"

if grep -Fq "fetch(" "$MOUNT"; then
  echo "FAIL: mount must not fetch"
  exit 1
fi

if grep -Fq "XMLHttpRequest" "$MOUNT"; then
  echo "FAIL: mount must not use XMLHttpRequest"
  exit 1
fi

if grep -Fq "sendBeacon" "$MOUNT"; then
  echo "FAIL: mount must not use sendBeacon"
  exit 1
fi

if grep -Fq "/api/" "$MOUNT"; then
  echo "FAIL: mount must not call backend APIs"
  exit 1
fi

if grep -Fq "localStorage.setItem" "$MOUNT"; then
  echo "FAIL: mount must not persist folder handles in localStorage"
  exit 1
fi

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/index.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js; then
  echo "FAIL: forbidden existing Profile/Anki/Google/local-backups panel files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/index.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js
  exit 1
fi

if grep -Fq "profile-local-backups-mount.js" frontend/wrapper-ui/apc-wrapper-local/index.html; then
  echo "FAIL: mount script should not be loaded from index.html in source-only stage"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$MOUNT"
  node - <<'NODE'
const mount = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js");
if (mount.marker !== "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12E_SOURCE_ONLY") throw new Error("bad marker");
if (!mount.isPrivateProfileRenderEvent({ detail: { page: "profile", user: { email: "x@example.invalid" } } })) throw new Error("private profile event not accepted");
if (mount.isPrivateProfileRenderEvent({ detail: { page: "profile", user: null } })) throw new Error("missing user accepted");
if (mount.isPrivateProfileRenderEvent({ detail: { page: "study", user: { email: "x@example.invalid" } } })) throw new Error("non-profile event accepted");
console.log("PASS node mount export smoke");
NODE
fi

grep -Fq "No deploy" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "detail.page === \"profile\"" "$DOC"
grep -Fq "detail.user exists" "$DOC"
grep -Fq "does not call fetch" "$DOC"
grep -Fq "does not store a selected folder handle yet" "$DOC"

echo "PASS stage-17k-z-r12e Profile local backups private mount source smoke"
