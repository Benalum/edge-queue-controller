#!/usr/bin/env bash
set -euo pipefail
APP="frontend/wrapper-ui/apc-wrapper-local"
printf '=== stage-17k-r16cd-match-profile-backup-folder-card-style-source-only smoke ===\n'
test -f "$APP/index.html"
test -f "$APP/privatepages/profile-local-backup-folder-panel.js"
test -f "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q '/privatepages/profile-local-backup-folder-panel.css' "$APP/index.html"
grep -q 'stage17k-r16cd-match-profile-backup-folder-card-style-source-only-20260710' "$APP/index.html"
grep -q 'private-shell\[data-private-page="profile"\] .apc-profile-backup-folder-panel' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'box-shadow: 0 14px 34px rgba(18, 38, 63, 0.09)' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'border-radius: 1.25rem' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'background: rgba(255, 255, 255, 0.96)' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'linear-gradient(135deg, #667eea, #65d6a6)' "$APP/privatepages/profile-local-backup-folder-panel.css"
grep -q 'data-apc-pick-backup-folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
grep -q 'data-apc-save-backup-folder' "$APP/privatepages/profile-local-backup-folder-panel.js"
! grep -q '/privatepages/profile-complete-local-backup-manager.js' "$APP/index.html"
! grep -q '/privatepages/profile-backup-folder-workspace.js' "$APP/index.html"
node --check "$APP/privatepages/profile-local-backup-folder-panel.js" >/dev/null
sha256sum \
  "$APP/index.html" \
  "$APP/privatepages/profile-local-backup-folder-panel.js" \
  "$APP/privatepages/profile-local-backup-folder-panel.css"
printf 'PASS stage-17k-r16cd-match-profile-backup-folder-card-style-source-only smoke\n'
