#!/usr/bin/env bash
set -euo pipefail
REPO="${REPO:-$HOME/Desktop/edge-queue-controller}"
APP="$REPO/frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16bz-profile-backup-folder-workspace-source-only smoke ===\n'

test -f "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'APC_PROFILE_BACKUP_FOLDER_WORKSPACE_R16BZ' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'showDirectoryPicker' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'webkitdirectory' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'buddies-who-study-current.json' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'buddies-who-study-current.previous.json' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'Save current to folder' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'mergeBackupPayload' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'buildBackupPayload' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q 'No Anki file writes' "$APP/privatepages/profile-backup-folder-workspace.js"
grep -q '/privatepages/profile-backup-folder-workspace.js' "$APP/index.html"
node --check "$APP/privatepages/profile-backup-folder-workspace.js" >/dev/null
sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/profile-backup-folder-workspace.js" \
  "$APP/privatepages/profile-complete-local-backup-manager.js" \
  "$APP/privatepages/local-data-coverage.js"
printf 'PASS stage-17k-r16bz-profile-backup-folder-workspace-source-only smoke\n'
