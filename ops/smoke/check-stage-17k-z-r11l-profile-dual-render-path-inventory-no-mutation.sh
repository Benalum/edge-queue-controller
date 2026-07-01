#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11l-profile-dual-render-path-inventory-no-mutation.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11l-profile-dual-render-path-inventory-no-mutation"

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

test -f "$OUT_DIR/source-file-presence."*.txt
test -f "$OUT_DIR/profile-route-source-scan."*.txt
test -f "$OUT_DIR/source-profile-feature-markers."*.txt
test -f "$OUT_DIR/public-route-probes."*.txt
test -f "$OUT_DIR/vm200-deployed-source-markers."*.txt

grep -q "two different Profile render paths" "$DOC"
grep -q "one Profile renderer only" "$DOC"

echo "PASS stage-17k-z-r11l Profile dual render path inventory smoke"
