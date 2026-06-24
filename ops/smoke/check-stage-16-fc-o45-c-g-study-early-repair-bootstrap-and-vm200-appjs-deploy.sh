#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-g-study-early-repair-bootstrap-and-vm200-appjs-deploy.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G" "$TARGET_FILE"
grep -q "APC_STUDY_SIGNED_IN_REPAIR_FC_O45_C_C" "$TARGET_FILE"
grep -q "apc-study-early-tools-fc-o45-c-g" "$TARGET_FILE"
grep -q "Create decks, add cards, review by difficulty" "$TARGET_FILE"
grep -q "Study tools" "$TARGET_FILE"
grep -q "Decks" "$TARGET_FILE"
grep -q "Cards" "$TARGET_FILE"
grep -q "Stats" "$TARGET_FILE"
grep -q "Review queue" "$TARGET_FILE"
grep -q "/api/study/decks" "$TARGET_FILE"
grep -q "/api/study/progress" "$TARGET_FILE"
grep -q "review-queue" "$TARGET_FILE"

grep -q "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No services were restarted" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-g-study-early-repair-bootstrap"
