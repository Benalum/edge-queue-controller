#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mv-b-ct204-data-authority-false-baseline-correction"
DOC="docs/${PHASE}.md"
PLAN_DOC="docs/phase-14j-mv-pvew-private-storage-lock-procedure-plan-no-apply.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"
test -f "$PLAN_DOC"

grep -Fq "DOCUMENTATION / SMOKE CORRECTION ONLY." "$DOC"
grep -Fq 'false // "missing"' "$DOC"
grep -Fq "private_storage_status.ct204.data_authority=false" "$DOC"
grep -Fq "there is no current public CT204 authority contract drift" "$DOC"
grep -Fq "APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE" "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_MV_B_CT204_DATA_AUTHORITY_FALSE_BASELINE_CORRECTION_DOC_READY" "$DOC"

grep -Fq "Public CT204 data_authority correction carried forward" "$PLAN_DOC"
grep -Fq "14J-MV-A corrected this as a jq boolean false handling issue" "$PLAN_DOC"
grep -Fq "private_storage_status.ct204.data_authority=false" "$PLAN_DOC"
grep -Fq "public status currently satisfies the intended CT204 non-authority field" "$PLAN_DOC"
grep -Fq "It must verify CT204 state directly from PVEW immediately before any mutation." "$PLAN_DOC"

if grep -Fq "A later public status contract repair phase should restore an explicit public-safe CT204 data_authority=false field." "$PLAN_DOC"; then
  echo "FAIL: stale public contract repair warning still present"
  exit 1
fi

echo "PASS: CT204 data_authority=false correction docs are consistent"
