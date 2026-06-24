#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-n-r2-restore-full-study-workspace.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2" "$TARGET_FILE"
grep -q "APC_STUDY_SINGLE_OWNER_FC_O45_C_L" "$TARGET_FILE"
grep -q "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K" "$TARGET_FILE"
grep -q "APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J" "$TARGET_FILE"
grep -q 'apcStudyFullWorkspacePanelFcO45CNR2' "$TARGET_FILE"
grep -q 'Create deck' "$TARGET_FILE"
grep -q 'Add card' "$TARGET_FILE"
grep -q 'Edit' "$TARGET_FILE"
grep -q 'Delete' "$TARGET_FILE"
grep -q 'Overall progress' "$TARGET_FILE"
grep -q 'Weekly progress' "$TARGET_FILE"
grep -q 'Deck/card statistics' "$TARGET_FILE"
grep -q '/api/study/progress' "$TARGET_FILE"
grep -q '/api/study/decks' "$TARGET_FILE"
grep -q '/api/study/cards' "$TARGET_FILE"
grep -q 'window.__apcStudyCanonicalFullWorkspaceFcO45CNR2 = true' "$TARGET_FILE"
grep -q 'window.apcStudyFullWorkspaceFcO45CNR2.mount' "$TARGET_FILE"
grep -q 'panel.id === "apcStudyFullWorkspacePanelFcO45CNR2"' "$TARGET_FILE"

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

grep -q "APC_STUDY_FULL_WORKSPACE_FC_O45_C_N_R2" "$DOC"
grep -q "Create deck" "$DOC"
grep -q "Weekly progress" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No service restart" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-n-r2-restore-full-study-workspace"
