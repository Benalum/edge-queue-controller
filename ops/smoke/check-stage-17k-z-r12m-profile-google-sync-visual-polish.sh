#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12m-profile-google-sync-visual-polish.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12m-profile-google-sync-visual-polish"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-private-polish.css"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "CSS-only VM200 static deploy" "$DOC"
grep -Fq "Only two files were deployed" "$DOC"
grep -Fq "No Google Drive sync JavaScript change" "$DOC"
grep -Fq "No Google consent logic change" "$DOC"

grep -Fq "profile-private-polish.css?v=stage17k-z-r12m-profile-google-sync-visual-polish-20260701" "$INDEX"
grep -Fq "APC_PRIVATE_PROFILE_GOOGLE_SYNC_VISUAL_POLISH_R12M_START" "$CSS"
grep -Fq '[data-apc-google-sync-profile-panel="true"]' "$CSS"
grep -Fq ".apc-google-sync-panel" "$CSS"
grep -Fq '[class*="google"][class*="sync"]' "$CSS"
grep -Fq 'input[type="checkbox"]' "$CSS"
grep -Fq "accent-color: #667eea" "$CSS"

grep -Fq "Google Drive sync" "$GOOGLE"
grep -Fq "Ready for explicit consent" "$GOOGLE"

grep -Fq "R12M_VM200_GOOGLE_SYNC_VISUAL_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12M smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12m Profile Google sync visual polish smoke"
