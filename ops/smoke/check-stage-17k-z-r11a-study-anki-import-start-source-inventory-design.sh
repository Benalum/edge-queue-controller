#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r11a-study-anki-import-start-source-inventory-design.md"

test -f "$DOC"

grep -q "No deploy" "$DOC"
grep -q "No server private Study persistence" "$DOC"
grep -q "No backend route addition" "$DOC"
grep -q "No Google Drive or OAuth work" "$DOC"
grep -q "No Anki source file mutation" "$DOC"

grep -q "study/import-sources/v1" "$DOC"
grep -q "study/anki-packages/v1" "$DOC"
grep -q "study/anki-notes/v1" "$DOC"
grep -q "study/anki-cards/v1" "$DOC"
grep -q "study/anki-media/v1" "$DOC"
grep -q "study/import-runs/v1" "$DOC"

grep -q "browser File API" "$DOC"
grep -q "note GUID" "$DOC"
grep -q "card ordinal" "$DOC"
grep -q "deck path" "$DOC"
grep -q "template name" "$DOC"
grep -q "original media filename" "$DOC"
grep -q "content hashes" "$DOC"

grep -q "Never upload private Anki content" "$DOC"
grep -q "no network calls" "$DOC"
grep -q "no backend routes" "$DOC"

if grep -q "/api/study" "$DOC"; then
  echo "FAIL: design doc should not reintroduce /api/study"
  exit 1
fi

echo "PASS stage-17k-z-r11a source inventory/design smoke"
