#!/usr/bin/env bash
set -euo pipefail
APP="frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16cc-style-profile-backup-folder-panel-source-only smoke ===\n'
test -f "$APP/index.html"
test -f "$APP/privatepages/profile-local-backup-folder-panel.js"
test -f "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q '/privatepages/profile-local-backup-folder-panel.css' "$APP/index.html"
grep -q 'stage17k-r16cc-style-profile-backup-folder-panel-source-only-20260710' "$APP/index.html"
grep -q 'apc-profile-backup-folder-panel' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'apc-profile-backup-actions' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'apc-profile-backup-folder-status' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'apc-profile-backup-folder-details' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'apc-profile-backup-folder-grid' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'data-apc-pick-backup-folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'data-apc-save-backup-folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
! grep -q '/privatepages/profile-complete-local-backup-manager.js' "$APP/index.html"
! grep -q '/privatepages/profile-backup-folder-workspace.js' "$APP/index.html"
node --check "$APP/privatepages/profile-local-backup-folder-panel.js" >/dev/null
sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/profile-local-backup-folder-panel.js" \
  "$APP/privatepages/profile-local-backup-folder-panel.css"
printf 'PASS stage-17k-r16cc-style-profile-backup-folder-panel-source-only smoke\n'
