#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ig-pvew-ct203-ct204-candidate-build-boundary-plan-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "NO_APPLY_BOUNDARY_PLAN_ONLY_CT203_CT204_NOT_CREATED" "$DOC"
grep -Fq "CT203" "$DOC"
grep -Fq "CT204" "$DOC"
grep -Fq "no authority migration" "$DOC"
grep -Fq "no user/platform data copy/import/dump" "$DOC"
grep -Fq "no encryption key output" "$DOC"
grep -Fq "no public route or tunnel mutation" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} docs-only no-apply boundary plan verified"
