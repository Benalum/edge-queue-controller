#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12b-vm200-deploy-profile-google-private-event-gate.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12b-vm200-deploy-profile-google-private-event-gate"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Only two files were deployed" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Profile fragment change" "$DOC"
grep -Fq "profile-google-sync-panel.js?v=stage17k-z-r12b-profile-google-private-event-gate-20260701" "$INDEX"
grep -Fq "PROFILE_GOOGLE_SYNC_PRIVATE_RENDER_EVENT_ONLY_R12A_R3" "$GOOGLE"
grep -Fq "function isPrivateProfileRenderEvent(event)" "$GOOGLE"
grep -Fq "Buddies Who Study local data" "$GOOGLE"
grep -Fq "R12B_VM200_TWO_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12B smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt
echo "PASS stage-17k-z-r12b VM200 deploy Profile Google private event gate smoke"
