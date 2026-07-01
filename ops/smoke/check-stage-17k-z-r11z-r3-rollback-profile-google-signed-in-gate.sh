#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11z-r3-rollback-profile-google-signed-in-gate.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11z-r3-rollback-profile-google-signed-in-gate"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
GOOGLE="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
test -f "$INDEX"
test -f "$GOOGLE"

grep -Fq "Emergency rollback" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No bandage" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Profile fragment change" "$DOC"
grep -Fq "No session gate change" "$DOC"
grep -Fq "No private shell change" "$DOC"
grep -Fq "No APKG mount change" "$DOC"

grep -Fq "profile-google-sync-panel.js?v=stage17k-z-r11w-apkg-preview-local-data-copy-20260701" "$INDEX"
grep -Fq "Buddies Who Study local data" "$GOOGLE"

if grep -Fq "PROFILE_GOOGLE_SYNC_SIGNED_IN_PRIVATE_PROFILE_ONLY_R11Y_R2" "$GOOGLE"; then
  echo "FAIL: bad signed-in gate marker remains"
  exit 1
fi

if grep -Fq "function hasSignedInPrivateProfile()" "$GOOGLE"; then
  echo "FAIL: bad signed-in gate function remains"
  exit 1
fi

test -f "$OUT_DIR/live-rollback."*.txt
test -f "$OUT_DIR/source-restore."*.txt
test -f "$OUT_DIR/public-static-proof."*.txt
test -f "$OUT_DIR/public-api-guard-proof."*.txt
test -f "$OUT_DIR/forbidden-source-check."*.txt

grep -Fq "R11Z_R3_LIVE_ROLLBACK_DONE" "$OUT_DIR/live-rollback."*.txt
grep -Fq "PASS local source restored to pre-gate Profile Google panel" "$OUT_DIR/source-restore."*.txt
grep -Fq "PASS public rollback static proof" "$OUT_DIR/public-static-proof."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-proof."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-proof."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-proof."*.txt
grep -Fq "PASS no forbidden broad/Profile/Anki source files changed" "$OUT_DIR/forbidden-source-check."*.txt

echo "PASS stage-17k-z-r11z-r3 rollback Profile Google signed-in gate smoke"
