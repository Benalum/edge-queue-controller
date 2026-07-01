#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12j-private-profile-visual-polish.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12j-private-profile-visual-polish"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-private-polish.css"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$CSS"

grep -Fq "Visual-only VM200 static deploy" "$DOC"
grep -Fq "Only two files were deployed" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Anki logic change" "$DOC"
grep -Fq "Known issue not fixed here" "$DOC"

grep -Fq "profile-private-polish.css?v=stage17k-z-r12j-private-profile-visual-polish-20260701" "$INDEX"
grep -Fq "APC_PRIVATE_PROFILE_VISUAL_POLISH_R12J_START" "$CSS"
grep -Fq '.private-shell[data-private-page="profile"]' "$CSS"
grep -Fq ".private-grid" "$CSS"
grep -Fq ".private-card" "$CSS"
grep -Fq ".profile-card" "$CSS"
grep -Fq "apc-profile-local-backups-panel" "$CSS"
grep -Fq "apc-anki-minimal-card" "$CSS"
grep -Fq "@media (max-width: 860px)" "$CSS"

grep -Fq "R12J_VM200_VISUAL_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12J smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12j private Profile visual polish smoke"
