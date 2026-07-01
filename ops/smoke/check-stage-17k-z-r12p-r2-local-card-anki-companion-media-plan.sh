#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12p-r2-local-card-anki-companion-media-plan.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12p-r2-local-card-anki-companion-media-plan"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Planning checkpoint only" "$DOC"
grep -Fq "No frontend deploy" "$DOC"
grep -Fq "No backend deploy" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "Media item record" "$DOC"
grep -Fq "Card media reference" "$DOC"
grep -Fq "study/media/v1" "$DOC"
grep -Fq "study/media-blobs/v1" "$DOC"
grep -Fq "study/card-media-refs/v1" "$DOC"
grep -Fq "Buddies Who Study native card media" "$DOC"
grep -Fq "Anki media support" "$DOC"
grep -Fq "Direct Anki profile or collection file" "$DOC"
grep -Fq "APKG import/preview" "$DOC"
grep -Fq "HTML and safety rules" "$DOC"
grep -Fq "Companion media bridge" "$DOC"
grep -Fq "Backup/export/import" "$DOC"
grep -Fq "Implementation milestones" "$DOC"
grep -Fq "R12Q" "$DOC"
grep -Fq "R12Y" "$DOC"
grep -Fq "Companion displays current Study card media" "$DOC"
grep -Fq "Do not start by parsing Anki media yet" "$DOC"

test -f "$OUT_DIR/source-inventory."*.txt
test -f "$OUT_DIR/current-markers."*.txt
test -f "$OUT_DIR/no-source-mutation-precheck."*.txt
grep -Fq "PASS no source mutation before docs" "$OUT_DIR/no-source-mutation-precheck."*.txt

echo "PASS stage-17k-z-r12p-r2 local card Anki Companion media plan smoke"
