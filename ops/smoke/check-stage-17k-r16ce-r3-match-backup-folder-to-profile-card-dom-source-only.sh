#!/usr/bin/env bash
set -euo pipefail
REPO="${REPO:-$HOME/Desktop/edge-queue-controller}"
cd "$REPO"
STAGE="stage-17k-r16ce-r3-match-backup-folder-to-profile-card-dom-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
MATCH_JS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-backup-folder-card-dom-match.js"
PANEL_JS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.js"
PANEL_CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.css"

for f in "$INDEX" "$MATCH_JS" "$PANEL_JS" "$PANEL_CSS"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

grep -q 'profile-backup-folder-card-dom-match.js' "$INDEX" || { echo "FAIL index missing DOM match loader"; exit 1; }
grep -q 'APC_PROFILE_BACKUP_FOLDER_CARD_DOM_MATCH_R16CE_R3' "$MATCH_JS" || { echo "FAIL match JS marker missing"; exit 1; }
grep -q 'Local backup folder' "$MATCH_JS" || { echo "FAIL match JS missing backup folder title search"; exit 1; }
grep -q 'Local settings' "$MATCH_JS" || { echo "FAIL match JS missing Local settings reference"; exit 1; }
grep -q 'Anki' "$MATCH_JS" || { echo "FAIL match JS missing Anki reference"; exit 1; }
grep -q 'copyClasses' "$MATCH_JS" || { echo "FAIL match JS missing class copy"; exit 1; }
grep -q 'MutationObserver' "$MATCH_JS" || { echo "FAIL match JS missing SPA mutation observer"; exit 1; }
grep -q 'apc-profile-backup-folder-card' "$PANEL_CSS" || { echo "FAIL CSS missing backup card selector"; exit 1; }
grep -q 'showDirectoryPicker' "$PANEL_JS" || { echo "FAIL backup panel missing folder picker logic"; exit 1; }
grep -q 'buddies-who-study-current.json' "$PANEL_JS" || { echo "FAIL backup panel missing current backup filename"; exit 1; }

sha256sum "$INDEX" "$MATCH_JS" "$PANEL_JS" "$PANEL_CSS"
echo "PASS $STAGE smoke"
