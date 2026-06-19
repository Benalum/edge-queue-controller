#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mv-pvew-private-storage-lock-procedure-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "NO-APPLY PLAN ONLY." "$DOC"
grep -Fq "Private storage has not been locked/unmounted yet." "$DOC"
grep -Fq "APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE" "$DOC"
grep -Fq "ct204_data_authority=missing" "$DOC"
grep -Fq "data_authority_paths=absent" "$DOC"
grep -Fq "public status contract drift" "$DOC"
grep -Fq "A later public status contract repair phase should restore an explicit public-safe CT204 data_authority=false field." "$DOC"
grep -Fq "Abort if any active process is using /srv/apc-private-data." "$DOC"
grep -Fq "Do not paste or run this apply command until Phase 14J-MW is explicitly approved." "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_MV_PVEW_PRIVATE_STORAGE_LOCK_PROCEDURE_PLAN_NO_APPLY_DOC_READY" "$DOC"

echo "PASS: no-apply lock procedure plan doc contains required gates"
