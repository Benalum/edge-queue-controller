#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11o-r3-commit-rollback-working-tree.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11o-r3-commit-rollback-working-tree"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Rollback commit recovery checkpoint" "$DOC"
grep -q "Does not deploy" "$DOC"
grep -q "Does not add a wrapper" "$DOC"
grep -q "Does not add a bandage" "$DOC"
grep -q "Keeps R11M-R2 evidence docs" "$DOC"
grep -q "No deploy in R11O-R3" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No signup change" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

test -f "$OUT_DIR/keep-r11m-r2-evidence."*.txt
test -f "$OUT_DIR/whitespace-fix."*.txt
test -f "$OUT_DIR/prior-live-rollback-evidence."*.txt
test -f "$OUT_DIR/source-rollback-state."*.txt

grep -q "PASS R11M-R2 evidence kept" "$OUT_DIR/keep-r11m-r2-evidence."*.txt
grep -q "PASS bad R11M-R2 cache-bust removed from source index" "$OUT_DIR/source-rollback-state."*.txt
grep -q "PASS bad R11M-R2 Anki loader removal marker removed from source" "$OUT_DIR/source-rollback-state."*.txt
grep -q "R11O_VM200_ROLLBACK_DONE" "$OUT_DIR/prior-live-rollback-evidence."*.txt

test -f docs/stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source.md
test -f ops/smoke/check-stage-17k-z-r11m-r2-remove-duplicate-profile-render-path-source.sh

if grep -R "stage17k-z-r11m-r2-canonical-profile-source-20260701" frontend/wrapper-ui/apc-wrapper-local/index.html >/dev/null; then
  echo "FAIL: bad R11M-R2 cache-bust remains in source index"
  exit 1
fi

if grep -R "R11M-R2 removed legacy Google sync Profile loader" frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js >/dev/null; then
  echo "FAIL: bad R11M-R2 Anki loader removal marker remains in source"
  exit 1
fi

echo "PASS stage-17k-z-r11o-r3 commit rollback working tree smoke"
