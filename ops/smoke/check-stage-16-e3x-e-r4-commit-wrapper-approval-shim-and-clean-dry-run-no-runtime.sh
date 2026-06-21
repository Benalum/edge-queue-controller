#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3x-e-r4-commit-wrapper-approval-shim-and-clean-dry-run-no-runtime.md"
WRAPPER="ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh"

echo "=== Stage 16 E3X-E-R4 smoke: wrapper approval shim committed, no runtime ==="

test -s "$DOC"
test -x "$WRAPPER"

grep -F "Commit Wrapper Approval Shim and Clean Dry-Run, No Runtime" "$DOC"
grep -F "E3X_E_R4_COMMIT_WRAPPER_APPROVAL_SHIM_AND_CLEAN_DRY_RUN_NO_RUNTIME_OK" "$DOC"
grep -F "R3 inserted the approval compatibility shim successfully" "$DOC"
grep -F "HEAD/origin/main/remote: d2f698c" "$DOC"
grep -F "JOB31_RECOVERY_STATE id=31 status=queued attempts=0" "$DOC"
grep -F "E3X_E_R4_ELIGIBLE_SMALL_MODEL_JOB_COUNT=1" "$DOC"
grep -F "E3X_E_R4_DB_RECOVERY_OK" "$DOC"
grep -F "E3X_E_R4_WRAPPER_SHIM_VALIDATION_OK" "$DOC"
grep -F "E3W_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "E3W_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "Allowed required approval values are explicitly whitelisted" "$DOC"
grep -F "E3X-E-R4 did not:" "$DOC"
grep -F "claim job 31" "$DOC"
grep -F "call a model" "$DOC"
grep -F "E3X-E-R5 — approved small-model timeout-safe runtime proof for job 31" "$DOC"
grep -F "APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY" "$DOC"
grep -F "Do not rerun E3V-Q" "$DOC"
grep -F "Do not retry job 29" "$DOC"
grep -F "Do not rerun job 30" "$DOC"
grep -F "Use job 31 only for the approved small-model completion proof path" "$DOC"

grep -F "E3X_E_APPROVAL_COMPAT_SHIM_BEGIN" "$WRAPPER"
grep -F "E3W_REQUIRED_APPROVAL" "$WRAPPER"
grep -F "RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true" "$WRAPPER"
bash -n "$WRAPPER"

echo "E3X_E_R4_COMMIT_WRAPPER_APPROVAL_SHIM_AND_CLEAN_DRY_RUN_NO_RUNTIME_SMOKE_OK"
