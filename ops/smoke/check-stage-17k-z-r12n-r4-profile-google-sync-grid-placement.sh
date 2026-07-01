#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12n-r4-profile-google-sync-grid-placement.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12n-r4-profile-google-sync-grid-placement"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-private-polish.css"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Profile Google Sync Grid Placement" "$DOC"
grep -Fq "Only three files were deployed" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Google consent logic change" "$DOC"

grep -Fq "profile-google-sync-panel.js?v=stage17k-z-r12n-r4-profile-google-sync-grid-placement-20260701" "$INDEX"
grep -Fq "profile-private-polish.css?v=stage17k-z-r12n-r4-profile-google-sync-grid-placement-20260701" "$INDEX"
grep -Fq "APC_PROFILE_GOOGLE_SYNC_GRID_PLACEMENT_R12N_R4" "$GOOGLE"
grep -Fq '.private-shell[data-private-page="profile"] .private-grid' "$GOOGLE"
grep -Fq "const host = findProfileAnchor();" "$GOOGLE"
grep -Fq "host.appendChild(panel);" "$GOOGLE"
grep -Fq "PROFILE_GOOGLE_SYNC_PRIVATE_RENDER_EVENT_ONLY_R12A_R3" "$GOOGLE"
grep -Fq "detail.page === 'profile' && detail.user" "$GOOGLE"
grep -Fq "APC_PRIVATE_PROFILE_GOOGLE_SYNC_GRID_CARD_R12N_R4" "$CSS"

grep -Fq "R12N_R4_VM200_GOOGLE_SYNC_GRID_PLACEMENT_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12N-R4 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12n-r4 Profile Google sync grid placement smoke"
