#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11o-r2-rollback-commit-recovery-keep-evidence.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11o-r2-rollback-commit-recovery-keep-evidence"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Rollback commit recovery checkpoint" "$DOC"
grep -q "R11M-R2 evidence docs are intentionally kept" "$DOC"
grep -q "not a wrapper or bandage" "$DOC"
grep -q "No deploy in R11O-R2" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No signup change" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

test -f "$OUT_DIR/restore-r11m-r2-evidence."*.txt
test -f "$OUT_DIR/source-rollback-check."*.txt
test -f "$OUT_DIR/public-rollback-confirm."*.txt
test -f "$OUT_DIR/public-api-guard-confirm."*.txt

grep -q "PASS bad R11M-R2 cache-bust removed from source index" "$OUT_DIR/source-rollback-check."*.txt
grep -q "PASS public root no longer references bad R11M-R2 cache-bust" "$OUT_DIR/public-rollback-confirm."*.txt
grep -q "api_system_status=200" "$OUT_DIR/public-api-guard-confirm."*.txt
grep -q "api_me_status=401" "$OUT_DIR/public-api-guard-confirm."*.txt
grep -q "signup_status=403" "$OUT_DIR/public-api-guard-confirm."*.txt

test -f docs/stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source.md
test -f ops/smoke/check-stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source.sh

if git status --short | grep -E '^ D |^D  ' | grep -q 'stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source'; then
  echo "FAIL: R11M-R2 evidence deletion still staged or present"
  exit 1
fi

if grep -R "stage17k-z-r11m-r2-canonical-profile-source-20260701" frontend/wrapper-ui/apc-wrapper-local/index.html >/dev/null; then
  echo "FAIL: bad R11M-R2 cache-bust remains in source index"
  exit 1
fi

echo "PASS stage-17k-z-r11o-r2 rollback commit recovery smoke"
