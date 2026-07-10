#!/usr/bin/env bash
set -euo pipefail
REPO="${REPO:-$HOME/Desktop/edge-queue-controller}"
cd "$REPO"
STAGE="stage-17k-r16cf-place-profile-backup-folder-inside-card-grid-source-only"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL_JS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.js"
PLACE_JS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-backup-folder-card-placement-fix.js"
PANEL_CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.css"

printf '=== %s smoke ===\n' "$STAGE"
for f in "$INDEX" "$PANEL_JS" "$PLACE_JS" "$PANEL_CSS"; do
  test -f "$f" || { echo "FAIL missing $f"; exit 1; }
done

grep -q 'profile-backup-folder-card-placement-fix.js' "$INDEX" || { echo 'FAIL index missing placement fix loader'; exit 1; }
grep -q 'APC_PROFILE_BACKUP_FOLDER_CARD_PLACEMENT_FIX_R16CF' "$PLACE_JS" || { echo 'FAIL placement marker missing'; exit 1; }
grep -q 'data-apc-local-backup-folder-panel-r16cb' "$PLACE_JS" || { echo 'FAIL placement selector missing'; exit 1; }
grep -q 'profileLocalFirstSettings' "$PLACE_JS" || { echo 'FAIL Local settings anchor missing'; exit 1; }
grep -q 'findAnkiCard' "$PLACE_JS" || { echo 'FAIL Anki placement anchor missing'; exit 1; }
grep -q 'insertBefore(panel, ankiCard)' "$PLACE_JS" || { echo 'FAIL does not insert before Anki card'; exit 1; }
grep -q 'apc-private-page-rendered' "$PLACE_JS" || { echo 'FAIL SPA render listener missing'; exit 1; }
grep -q 'MutationObserver' "$PLACE_JS" || { echo 'FAIL mutation observer missing'; exit 1; }
grep -q 'APC_PROFILE_BACKUP_FOLDER_CARD_PLACEMENT_FIX_R16CF_CSS' "$PANEL_CSS" || { echo 'FAIL placement CSS marker missing'; exit 1; }
grep -q 'grid-template-columns: 1fr' "$PANEL_CSS" || { echo 'FAIL action buttons not constrained'; exit 1; }
node --check "$PLACE_JS" >/dev/null
sha256sum "$INDEX" "$PLACE_JS" "$PANEL_JS" "$PANEL_CSS"
printf 'PASS %s smoke\n' "$STAGE"
