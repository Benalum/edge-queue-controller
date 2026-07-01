#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12o-profile-card-order-polish.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12o-profile-card-order-polish"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-private-polish.css"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "CSS-only VM200 static deploy" "$DOC"
grep -Fq "Top row" "$DOC"
grep -Fq "Buddies Who Study local backups" "$DOC"
grep -Fq "Second row" "$DOC"
grep -Fq "No Google Drive sync JavaScript change" "$DOC"
grep -Fq "No local backups logic change" "$DOC"
grep -Fq "No Anki logic change" "$DOC"

grep -Fq "profile-private-polish.css?v=stage17k-z-r12o-profile-card-order-polish-20260701" "$INDEX"
grep -Fq "APC_PRIVATE_PROFILE_CARD_ORDER_POLISH_R12O_START" "$CSS"
grep -Fq "order: 10" "$CSS"
grep -Fq "order: 20" "$CSS"
grep -Fq "order: 30" "$CSS"
grep -Fq "order: 40" "$CSS"
grep -Fq ".apc-profile-local-backups-panel" "$CSS"
grep -Fq ".apc-anki-minimal-card" "$CSS"
grep -Fq "data-apc-google-sync-profile-panel" "$CSS"

grep -Fq "R12O_VM200_PROFILE_CARD_ORDER_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12O smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12o Profile card order polish smoke"
