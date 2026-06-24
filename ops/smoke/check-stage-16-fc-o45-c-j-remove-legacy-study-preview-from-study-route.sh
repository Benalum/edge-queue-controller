#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-j-remove-legacy-study-preview-from-study-route.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J" "$TARGET_FILE"
grep -q "function renderCleanStudyRouteFcO45CJ" "$TARGET_FILE"
grep -q 'data-apc-study-route-cleanup="APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J"' "$TARGET_FILE"
grep -q 'const isStudyWrapperRoute = path === "/study-wrapper-preview";' "$TARGET_FILE"
grep -q 'if (path === "/study")' "$TARGET_FILE"
grep -q "renderCleanStudyRouteFcO45CJ();" "$TARGET_FILE"
grep -q "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G" "$TARGET_FILE"
grep -q "Create decks, add cards, review by difficulty, and track progress from the shared wrapper layout" "$TARGET_FILE"

if grep -qF 'const isStudyWrapperRoute = path === "/study-wrapper-preview" || path === "/study";' "$TARGET_FILE"; then
  echo "FAIL: real /study still points to legacy Study wrapper preview route"
  exit 1
fi

grep -q "APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No service restart" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-j-remove-legacy-study-preview-from-study-route"
