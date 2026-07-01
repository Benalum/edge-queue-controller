#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11z-r2-profile-google-signed-in-gate-commit-recovery.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11z-r2-profile-google-signed-in-gate-commit-recovery"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$INDEX"
test -f "$GOOGLE"

grep -Fq "Commit recovery checkpoint after interrupted R11Z" "$DOC"
grep -Fq "does not redeploy" "$DOC"
grep -Fq "No deploy in R11Z-R2" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No bandage" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Profile fragment change" "$DOC"
grep -Fq "No session gate change" "$DOC"
grep -Fq "No private shell change" "$DOC"

grep -Fq "profile-google-sync-panel.js?v=stage17k-z-r11z-profile-google-signed-in-gate-20260701" "$INDEX"
grep -Fq "PROFILE_GOOGLE_SYNC_SIGNED_IN_PRIVATE_PROFILE_ONLY_R11Y_R2" "$GOOGLE"
grep -Fq "function hasSignedInPrivateProfile()" "$GOOGLE"
grep -Fq "Buddies Who Study local data" "$GOOGLE"

test -f "$OUT_DIR/source-state."*.txt
test -f "$OUT_DIR/live-static-confirm."*.txt
test -f "$OUT_DIR/public-api-guard-confirm."*.txt
test -f "$OUT_DIR/forbidden-source-check."*.txt

grep -Fq "PASS R11Z source cache-bust and signed-in gate present" "$OUT_DIR/source-state."*.txt
grep -Fq "PASS R11Z signed-in gate is live" "$OUT_DIR/live-static-confirm."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-confirm."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-confirm."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-confirm."*.txt
grep -Fq "PASS no forbidden broad/Profile/Anki source files changed" "$OUT_DIR/forbidden-source-check."*.txt

echo "PASS stage-17k-z-r11z-r2 Profile Google signed-in gate commit recovery smoke"
