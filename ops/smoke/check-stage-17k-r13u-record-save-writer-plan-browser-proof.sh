#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13u-record-save-writer-plan-browser-proof.md"
OUT_DIR="docs/smoke/generated/stage-17k-r13u-record-save-writer-plan-browser-proof"

test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Record Save Writer Plan Browser Proof" "$DOC"
grep -Fq "Browser console proof passed" "$DOC"
grep -Fq "PASS_R13T_SAVE_WRITER_PLAN_PROOF" "$DOC"
grep -Fq "APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_WRITER_R13S_SOURCE_ONLY" "$DOC"
grep -Fq "buddies-who-study-current.json" "$DOC"
grep -Fq "buddies-who-study-current.previous.json" "$DOC"
grep -Fq "planCanWrite false" "$DOC"
grep -Fq "planWritesEnabled false" "$DOC"
grep -Fq "planSameFileWriteEnabled false" "$DOC"
grep -Fq "planCurrentFileWriteEnabled false" "$DOC"
grep -Fq "planPreviousFileWriteEnabled false" "$DOC"
grep -Fq "planRemovedFieldCount 4" "$DOC"
grep -Fq "planAfterLegacyFieldPaths []" "$DOC"
grep -Fq "2 decks" "$DOC"
grep -Fq "2 cards" "$DOC"
grep -Fq "16 sessions" "$DOC"
grep -Fq "0 media" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No current-file save" "$DOC"
grep -Fq "No same-file write path" "$DOC"

echo "PASS stage-17k-r13u record save writer plan browser proof smoke"
