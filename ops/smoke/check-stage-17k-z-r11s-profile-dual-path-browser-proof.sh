#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11s-profile-dual-path-browser-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11s-profile-dual-path-browser-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -q "Manual browser proof checkpoint after R11R" "$DOC"
grep -q "No deploy" "$DOC"
grep -q "No source patch" "$DOC"
grep -q "No wrapper" "$DOC"
grep -q "No bandage" "$DOC"
grep -q "No privatepages.js change" "$DOC"
grep -q "No Profile fragment change" "$DOC"
grep -q "No session gate change" "$DOC"
grep -q "No private shell change" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No Google Drive or OAuth activation" "$DOC"
grep -q "No Anki source file mutation" "$DOC"
grep -q "No real SQLite collection parsing" "$DOC"

test -f "$OUT_DIR/manual-browser-proof."*.txt
test -f "$OUT_DIR/r11r-smoke."*.txt

grep -q "Both Profile paths now match" "$OUT_DIR/manual-browser-proof."*.txt
grep -q "Site did not white-screen" "$OUT_DIR/manual-browser-proof."*.txt
grep -q "Site did not get stuck on Checking session" "$OUT_DIR/manual-browser-proof."*.txt
grep -q "Result: PASS" "$OUT_DIR/manual-browser-proof."*.txt
grep -q "PASS stage-17k-z-r11r VM200 static deploy Profile Google direct loader smoke" "$OUT_DIR/r11r-smoke."*.txt

echo "PASS stage-17k-z-r11s Profile dual-path browser proof smoke"
