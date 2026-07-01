#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11o-rollback-bad-profile-canonicalization.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11o-rollback-bad-profile-canonicalization"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Emergency rollback checkpoint" "$DOC"
grep -q "Checking session" "$DOC"
grep -q "2a7fe0a fix: remove duplicate profile render path" "$DOC"
grep -q "not a wrapper or bandage" "$DOC"
grep -q "Do not patch privatepages.js broadly" "$DOC"
grep -q "Do not add a wrapper" "$DOC"

test -f "$OUT_DIR/vm200-rollback."*.txt
test -f "$OUT_DIR/public-rollback-smoke."*.txt
test -f "$OUT_DIR/public-api-guard."*.txt
test -f "$OUT_DIR/source-revert."*.txt

grep -q "R11O_VM200_ROLLBACK_DONE" "$OUT_DIR/vm200-rollback."*.txt
grep -q "root_code=200" "$OUT_DIR/public-rollback-smoke."*.txt
grep -q "api_system_status=200" "$OUT_DIR/public-api-guard."*.txt
grep -q "api_me_status=401" "$OUT_DIR/public-api-guard."*.txt
grep -q "signup_status=403" "$OUT_DIR/public-api-guard."*.txt

if grep -R "stage17k-z-r11m-r2-canonical-profile-source-20260701" frontend/wrapper-ui/apc-wrapper-local/index.html >/dev/null; then
  echo "FAIL: bad R11M-R2 cache-bust remains in source index"
  exit 1
fi

echo "PASS stage-17k-z-r11o rollback bad Profile canonicalization smoke"
