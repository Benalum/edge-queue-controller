#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-o-polish-study-workspace-css-formatting.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_WORKSPACE_POLISH_FC_O45_C_O" "$TARGET_FILE"
grep -q "APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2" "$TARGET_FILE"
grep -q "APC_STUDY_SINGLE_OWNER_FC_O45_C_L" "$TARGET_FILE"
grep -q 'apc-study-workspace-polish-fc-o45-c-o' "$TARGET_FILE"
grep -q 'function displayValue' "$TARGET_FILE"
grep -q 'function firstValue' "$TARGET_FILE"
grep -q 'function ensureWorkspaceStyles' "$TARGET_FILE"
grep -q 'New deck name' "$TARGET_FILE"
grep -q 'Card front' "$TARGET_FILE"
grep -q 'Card back' "$TARGET_FILE"
grep -q 'const cardMetric = firstValue' "$TARGET_FILE"

if grep -qF 'metric("Cards", stats.card_count || stats.cards || stats.total_cards || "—")' "$TARGET_FILE"; then
  echo "FAIL: old object-prone stats card metric still present"
  exit 1
fi

if grep -qF '[object Object]' "$TARGET_FILE"; then
  echo "FAIL: literal [object Object] unexpectedly present"
  exit 1
fi

if grep -qF 'Study tools load after sign-in. Deck/card data was not loaded' "$TARGET_FILE"; then
  echo "FAIL: signed-out 401 Study tools text returned"
  exit 1
fi

if grep -qF 'Loading your durable Study session and signed-in Study tools...' "$TARGET_FILE"; then
  echo "FAIL: placeholder Study dashboard text returned"
  exit 1
fi

if grep -qF 'const isStudyWrapperRoute = path === "/study-wrapper-preview" || path === "/study";' "$TARGET_FILE"; then
  echo "FAIL: real /study still points to legacy Study wrapper preview route"
  exit 1
fi

grep -q "APC_STUDY_WORKSPACE_POLISH_FC_O45_C_O" "$DOC"
grep -q "scoped CSS" "$DOC"
grep -q "array/object-safe" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No service restart" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-o-polish-study-workspace-css-formatting"
