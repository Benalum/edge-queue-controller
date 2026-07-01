#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11i-vm200-static-deploy-target-inventory-no-deploy.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11i-vm200-static-deploy-target-inventory-no-deploy"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "No deploy" "$DOC"
grep -q "No frontend live mutation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"
grep -q "No media extraction" "$DOC"

grep -q "frontend/wrapper-ui/apc-wrapper-local/index.html" "$DOC"
grep -q "profile-anki-preview-mount.js" "$DOC"
grep -q "private Study routes remain removed" "$DOC"

test -f "$OUT_DIR/local-source-files."*.txt
test -f "$OUT_DIR/local-script-order."*.txt
test -f "$OUT_DIR/public-live-static-predeploy."*.txt
test -f "$OUT_DIR/vm200-readonly-static-path-probe."*.txt

grep -q "PASS script order" "$OUT_DIR/local-script-order."*.txt

if grep -R "rsync\|scp " "$OUT_DIR/vm200-readonly-static-path-probe."*.txt >/tmp/apc-r11i-copy-check.txt 2>/dev/null; then
  echo "INFO: copy words may appear in read-only config output; no copy command was executed by this smoke."
fi

echo "PASS stage-17k-z-r11i VM200 static deploy target inventory smoke"
