#!/usr/bin/env bash
set -euo pipefail
STAGE="stage-17k-r16ce-profile-backup-folder-card-style-guard-source-only"
APP="frontend/wrapper-ui/apc-wrapper-local"
INDEX="$APP/index.html"
CSS="$APP/privatepages/profile-local-backup-folder-panel.css"
GUARD="$APP/privatepages/profile-local-backup-folder-card-style-guard.js"
PANEL="$APP/privatepages/profile-local-backup-folder-panel.js"

test -f "$INDEX"
test -f "$CSS"
test -f "$GUARD"
test -f "$PANEL"
grep -q '/privatepages/profile-local-backup-folder-panel.css?v=stage17k-r16ce-profile-backup-folder-card-style-guard-source-only-20260710' "$INDEX"
grep -q '/privatepages/profile-local-backup-folder-card-style-guard.js?v=stage17k-r16ce-profile-backup-folder-card-style-guard-source-only-20260710' "$INDEX"
grep -q 'APC_PROFILE_BACKUP_FOLDER_CARD_STYLE_GUARD_R16CE' "$GUARD"
grep -q 'data-apc-local-backup-folder-panel-r16cb' "$CSS"
grep -q 'box-shadow' "$CSS"
grep -q 'input\[type="file"\]' "$CSS"
grep -q 'private-card apc-profile-backup-folder-panel' "$PANEL"
node --check "$GUARD" >/dev/null
node --check "$PANEL" >/dev/null
sha256sum "$INDEX" "$CSS" "$GUARD" "$PANEL"
echo "PASS ${STAGE} smoke"
