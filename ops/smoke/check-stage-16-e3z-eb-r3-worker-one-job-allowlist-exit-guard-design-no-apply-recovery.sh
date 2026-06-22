#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-eb-r3-worker-one-job-allowlist-exit-guard-design-no-apply-recovery.md"

[ -f "$DOC" ] || { echo "MISSING_DOC=$DOC"; exit 1; }

needles=(
  "repository-only no-apply design checkpoint"
  "Recovery note"
  "job 45 direct installed-worker one-shot"
  "job 46 service-managed transient systemd one-shot"
  "EDGE_ALLOWED_JOB_IDS"
  "EDGE_EXIT_AFTER_ONE_SUCCESS"
  "EDGE_MAX_RUNTIME_SECONDS"
  "EDGE_REFUSE_IF_SCHEDULER_ACTIVE"
  "EDGE_REFUSE_IF_TIMER_ACTIVE"
  "EDGE_PROOF_MODE=limited_persistent_one_job"
  "REFUSE_WORKER_ALLOWED_JOB_IDS_INVALID"
  "REFUSE_WORKER_EXIT_AFTER_ONE_SUCCESS_REQUIRED"
  "REFUSE_WORKER_MAX_RUNTIME_SECONDS_INVALID"
  "REFUSE_WORKER_MAX_RUNTIME_SECONDS_EXCEEDED"
  "REFUSE_WORKER_SCHEDULER_ACTIVE"
  "REFUSE_WORKER_TIMER_ACTIVE"
  "REFUSE_WORKER_EXACT_JOB_CLAIM_REQUIRED"
  "REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED"
  "REFUSE_WORKER_EXACT_MARKER_MISMATCH"
  "E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS"
  "Preserve the existing"
  "--once --job-id behavior still works"
  "disabled worker still refuses with REFUSE_WORKER_DISABLED"
  "APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START"
  "APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_ONLY"
  "Proceed with EC"
)

for needle in "${needles[@]}"; do
  grep -Fq -- "$needle" "$DOC" || { echo "MISSING_NEEDLE=$needle"; exit 1; }
done

echo "E3Z_EB_R3_SMOKE_OK=1"
