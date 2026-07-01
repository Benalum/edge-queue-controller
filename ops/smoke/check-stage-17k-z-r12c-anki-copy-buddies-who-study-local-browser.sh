#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12c-anki-copy-buddies-who-study-local-browser.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12c-anki-copy-buddies-who-study-local-browser"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ANKI="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Only two files were deployed" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "anki-manifest-panel.js?v=stage17k-z-r12c-anki-copy-buddies-local-browser-20260701" "$INDEX"
grep -Fq "Buddies Who Study reads deck names and card counts locally in this browser." "$ANKI"

if grep -Fq "APC reads deck names and card counts locally in this browser." "$ANKI"; then
  echo "FAIL: old Anki APC copy remains"
  exit 1
fi

grep -Fq "R12C_VM200_TWO_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12C smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12c Anki copy Buddies Who Study local browser smoke"
