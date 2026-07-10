#!/usr/bin/env bash
set -euo pipefail
APP="frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16ca-profile-remove-backup-drive-local-profile-source-only smoke ===\n'

test -f "$APP/privatepages/profile-local-first-ui-cleanup.js"
grep -q 'APC_PROFILE_LOCAL_FIRST_UI_CLEANUP_R16CA' "$APP/privatepages/profile-local-first-ui-cleanup.js"
grep -q 'data-apc-complete-local-backup-manager' "$APP/privatepages/profile-local-first-ui-cleanup.js"
grep -q 'data-apc-backup-folder-workspace' "$APP/privatepages/profile-local-first-ui-cleanup.js"
grep -q 'data-apc-google-sync-profile-panel' "$APP/privatepages/profile-local-first-ui-cleanup.js"

node --check "$APP/privatepages/profile-local-first-ui-cleanup.js" >/dev/null

! grep -q 'Local profile' "$APP/privatepages/pages/profile.html"
! grep -q 'Email / mode' "$APP/privatepages/pages/profile.html"
! grep -q 'browser-local@buddies.local' "$APP/privatepages/pages/profile.html"
grep -q 'profileLocalFirstSettings' "$APP/privatepages/pages/profile.html"

for removed in \
  '/privatepages/profile-google-sync-panel.js' \
  '/privatepages/google-sync-config.js' \
  '/privatepages/profile-complete-local-backup-manager.js' \
  '/privatepages/profile-backup-folder-workspace.js' \
  '/privatepages/profile-local-backups-panel.js' \
  '/privatepages/profile-local-backups-mount.js' \
  '/privatepages/local-backup-current-file-save-plan.js' \
  '/privatepages/local-backup-current-file-save-writer.js'; do
  if grep -q "$removed" "$APP/index.html"; then
    echo "FAIL: removed Profile section script still loaded: $removed"
    exit 1
  fi
done

grep -q '/privatepages/profile-local-first-settings.js' "$APP/index.html"
grep -q '/privatepages/profile-companion-custom-media.js' "$APP/index.html"
grep -q '/privatepages/profile-local-first-ui-cleanup.js' "$APP/index.html"
grep -q '/privatepages/study-card-local-media.js' "$APP/index.html"
grep -q '/privatepages/companion-card-media-display.js' "$APP/index.html"

sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/pages/profile.html" \
  "$APP/privatepages/profile-local-first-ui-cleanup.js" \
  "$APP/privatepages/profile-local-first-settings.js" \
  "$APP/privatepages/profile-companion-custom-media.js"

printf 'PASS stage-17k-r16ca-profile-remove-backup-drive-local-profile-source-only smoke\n'
