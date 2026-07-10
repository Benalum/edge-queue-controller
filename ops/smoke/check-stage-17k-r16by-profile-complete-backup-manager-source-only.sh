#!/usr/bin/env bash
set -euo pipefail
REPO="${REPO:-$HOME/Desktop/edge-queue-controller}"
APP="$REPO/frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16by-profile-complete-backup-manager-source-only smoke ===\n'

test -f "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'APC_PROFILE_COMPLETE_LOCAL_BACKUP_MANAGER_R16BY' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'buddies-who-study-current.json' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'Download .*CURRENT_FILE_NAME' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'data-apc-complete-backup-preview-current' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'data-apc-complete-backup-open-file' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'data-apc-local-backup-open-current' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'study/decks/v1' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'study/cards/v1' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'local/media-blobs/v1' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'companion/preferences/v1' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q 'anki/read-only-policy/v1' "$APP/privatepages/profile-complete-local-backup-manager.js"
grep -q '/privatepages/profile-complete-local-backup-manager.js' "$APP/index.html"
node --check "$APP/privatepages/profile-complete-local-backup-manager.js" >/dev/null
sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/profile-complete-local-backup-manager.js" \
  "$APP/privatepages/local-data-coverage.js" \
  "$APP/privatepages/study-card-local-media.js" \
  "$APP/privatepages/profile-companion-custom-media.js"
printf 'PASS stage-17k-r16by-profile-complete-backup-manager-source-only smoke\n'
