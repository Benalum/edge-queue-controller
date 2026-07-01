#!/usr/bin/env bash
set -euo pipefail

PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
DOC="docs/stage-17k-z-r12d-profile-local-backups-panel-source-no-mount.md"

test -f "$PANEL"
test -f "$DOC"

grep -Fq "APC_PROFILE_LOCAL_BACKUPS_PANEL_R12D_SOURCE_ONLY" "$PANEL"
grep -Fq "Buddies Who Study local backups" "$PANEL"
grep -Fq "Buddies Who Study local data" "$PANEL"
grep -Fq "showDirectoryPicker" "$PANEL"
grep -Fq "Folder picker is not supported in this browser. Use download backup instead." "$PANEL"
grep -Fq "Download backup file" "$PANEL"
grep -Fq "Do not choose your Anki profile folder. Use a separate backup folder." "$PANEL"
grep -Fq "uploadsToServer: false" "$PANEL"
grep -Fq "modifiesAnkiSourceFiles: false" "$PANEL"
grep -Fq "includesAnkiSourceFileBytes: false" "$PANEL"
grep -Fq "study/cards/v1" "$PANEL"
grep -Fq "study/decks/v1" "$PANEL"
grep -Fq "study/progress/v1" "$PANEL"
grep -Fq "study/sessions/v1" "$PANEL"
grep -Fq "study/store-state/v1" "$PANEL"
grep -Fq "root.APC_PROFILE_LOCAL_BACKUPS_PANEL = api" "$PANEL"

if grep -Fq "fetch(" "$PANEL"; then
  echo "FAIL: local backups panel must not fetch"
  exit 1
fi

if grep -Fq "XMLHttpRequest" "$PANEL"; then
  echo "FAIL: local backups panel must not use XMLHttpRequest"
  exit 1
fi

if grep -Fq "sendBeacon" "$PANEL"; then
  echo "FAIL: local backups panel must not use sendBeacon"
  exit 1
fi

if grep -Fq "/api/" "$PANEL"; then
  echo "FAIL: local backups panel must not call backend APIs"
  exit 1
fi

if ! git diff --quiet -- \
  frontend/wrapper-ui/apc-wrapper-local/index.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
  frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js; then
  echo "FAIL: forbidden existing Profile/Anki/Google files changed"
  git diff -- \
    frontend/wrapper-ui/apc-wrapper-local/index.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/privatepages.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js \
    frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-mount.js
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$PANEL"
  node - <<'NODE'
const panel = require("./frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js");
if (panel.marker !== "APC_PROFILE_LOCAL_BACKUPS_PANEL_R12D_SOURCE_ONLY") throw new Error("bad marker");
if (!panel.renderPreviewHtml().includes("Buddies Who Study local backups")) throw new Error("missing title");
if (!panel.renderPreviewHtml().includes("Download backup file")) throw new Error("missing download");
if (!panel.studyDocKeys.includes("study/decks/v1")) throw new Error("missing study doc key");
const fileName = panel.backupFileName("2026-07-01T00:00:00.000Z");
if (!fileName.includes("buddies-who-study-local-backup-v1-")) throw new Error("bad filename");
console.log("PASS node module export smoke");
NODE
fi

grep -Fq "No mount" "$DOC"
grep -Fq "No deploy" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "Added:" "$DOC"
grep -Fq "privatepages/profile-local-backups-panel.js" "$DOC"

echo "PASS stage-17k-z-r12d Profile local backups panel source/no-mount smoke"
