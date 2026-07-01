#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11d-profile-anki-source-inventory-and-reuse-plan.md"
SCAN_DIR="docs/smoke/generated/stage-17k-z-r11d-profile-anki-source-inventory-and-reuse-plan"

test -f "$DOC"
test -d "$SCAN_DIR"

grep -q "No deploy" "$DOC"
grep -q "No UI activation" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No local Study doc write" "$DOC"
grep -q "No real SQLite parsing" "$DOC"
grep -q "No media extraction" "$DOC"

grep -q "APC_ANKI_IMPORT_LOCAL.inspectApkgFile" "$DOC"
grep -q "Profile Anki surface" "$DOC"
grep -q "Original Anki files must not be mutated" "$DOC"

test -f "$SCAN_DIR/source-file-presence."*.txt
test -f "$SCAN_DIR/profile-anki-source-scan."*.txt
test -f "$SCAN_DIR/capability-markers."*.txt

if grep -R "profile-anki-source-scan.*profile-anki-source-scan" "$SCAN_DIR" >/tmp/apc-r11d-recursive-scan-check.txt 2>/dev/null; then
  echo "FAIL: recursive scan evidence detected"
  cat /tmp/apc-r11d-recursive-scan-check.txt
  exit 1
fi

echo "PASS stage-17k-z-r11d profile anki source inventory smoke"
