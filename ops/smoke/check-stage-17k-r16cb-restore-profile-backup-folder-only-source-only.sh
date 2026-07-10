#!/usr/bin/env bash
set -euo pipefail
APP="frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16cb-restore-profile-backup-folder-only-source-only smoke ===\n'

test -f "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'APC_PROFILE_LOCAL_BACKUP_FOLDER_PANEL_R16CB' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'Local backup folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'Pick Backup Folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'Save current backup' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'Scan folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'buddies-who-study-current.json' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'buddies-who-study-current.previous.json' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'showDirectoryPicker' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'APC_STUDY_STORE' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'APC_LOCAL_SAVE' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'writesAnkiFiles: false' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q '/privatepages/profile-local-backup-folder-panel.js' "$APP/index.html"
node --check "$APP/privatepages/profile-local-backup-folder-panel.js" >/dev/null

# Keep the removed clutter removed.
! grep -q '/privatepages/profile-complete-local-backup-manager.js' "$APP/index.html"
! grep -q '/privatepages/profile-backup-folder-workspace.js' "$APP/index.html"
! grep -q '/privatepages/profile-google-sync-panel.js' "$APP/index.html"
! grep -q '/privatepages/google-sync-config.js' "$APP/index.html"
! grep -q 'Local profile' "$APP/privatepages/pages/profile.html"

git diff --check
sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/profile-local-backup-folder-panel.js" \
  "$APP/privatepages/profile-local-first-ui-cleanup.js" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/profile-companion-custom-media.js"
printf 'PASS stage-17k-r16cb-restore-profile-backup-folder-only-source-only smoke\n'
