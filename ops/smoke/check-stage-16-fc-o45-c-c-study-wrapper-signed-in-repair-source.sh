#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-c-study-wrapper-signed-in-repair-source.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_SIGNED_IN_REPAIR_FC_O45_C_C" "$TARGET_FILE"
grep -q "apc-study-signed-in-tools-fc-o45-c-c" "$TARGET_FILE"
grep -q "Study tools" "$TARGET_FILE"
grep -q "Decks" "$TARGET_FILE"
grep -q "Cards" "$TARGET_FILE"
grep -q "Stats" "$TARGET_FILE"
grep -q "Review queue" "$TARGET_FILE"
grep -q "/api/study/decks" "$TARGET_FILE"
grep -q "/api/study/progress" "$TARGET_FILE"
grep -q "review-queue" "$TARGET_FILE"
grep -q "/api/me" "$TARGET_FILE"

grep -q "signed-in Study page" "$DOC"
grep -q "No live deploy" "$DOC"
grep -q "No DB writes" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-c-study-wrapper-signed-in-repair-source"
