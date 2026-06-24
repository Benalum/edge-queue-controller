#!/usr/bin/env bash
set -euo pipefail

TARGET_FILE="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-c-k-clean-study-tools-auth-remove-placeholder.md"

test -f "$TARGET_FILE"
test -f "$DOC"

grep -q "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K" "$TARGET_FILE"
grep -q "APC_STUDY_ROUTE_CLEANUP_FC_O45_C_J" "$TARGET_FILE"
grep -q "APC_STUDY_EARLY_REPAIR_BOOTSTRAP_FC_O45_C_G" "$TARGET_FILE"
grep -q 'typeof api === "function"' "$TARGET_FILE"
grep -q 'path.slice(4)' "$TARGET_FILE"
grep -q 'data-apc-study-tools-auth-cleanup="APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K"' "$TARGET_FILE"
grep -q 'aria-hidden="true"' "$TARGET_FILE"
grep -q 'const isStudyWrapperRoute = path === "/study-wrapper-preview";' "$TARGET_FILE"

if grep -qF 'Study tools load after sign-in. Deck/card data was not loaded' "$TARGET_FILE"; then
  echo "FAIL: signed-out 401 Study tools panel text still present"
  exit 1
fi

if grep -qF 'Loading your durable Study session and signed-in Study tools...' "$TARGET_FILE"; then
  echo "FAIL: temporary placeholder Study dashboard text still present"
  exit 1
fi

if grep -qF 'const isStudyWrapperRoute = path === "/study-wrapper-preview" || path === "/study";' "$TARGET_FILE"; then
  echo "FAIL: real /study still points to legacy Study wrapper preview route"
  exit 1
fi

grep -q "APC_STUDY_TOOLS_AUTH_CLEANUP_FC_O45_C_K" "$DOC"
grep -q "No DB write" "$DOC"
grep -q "No service restart" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$TARGET_FILE"
fi

echo "RESULT=PASS stage-16-fc-o45-c-k-clean-study-tools-auth-remove-placeholder"
