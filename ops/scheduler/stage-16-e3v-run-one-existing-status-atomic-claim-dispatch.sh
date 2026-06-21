#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-16-e3v-run-one-existing-status-atomic-claim-dispatch"
REQUIRED_APPROVAL="APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY"
PASS_MARKER="E3V_OPTION_B_ATOMIC_CLAIM_ONE_SHOT_DISPATCH_OK"

MODE="${1:-}"
EXPECTED_MODEL="${EXPECTED_MODEL:-qwen2.5:32b-instruct-q4_K_M}"
CTID="${CTID:-203}"
CT203_DB_PATH="${CT203_DB_PATH:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"
RUN_ROOT="${RUN_ROOT:-/tmp}"
MAX_RUNTIME_SECONDS="${MAX_RUNTIME_SECONDS:-7200}"

echo "STAGE=$STAGE"
echo "STATIC_ARTIFACT_STATUS=created_not_runtime_enabled"
echo "DEFAULT_REFUSAL=true"

case "$MODE" in
  --dry-run)
    echo "MODE=dry-run"
    echo "NO_DB_WRITE"
    echo "NO_SCHEMA_MIGRATION"
    echo "NO_DB_CLAIM"
    echo "NO_HELPER_CALL"
    echo "NO_ADAPTER_CALL"
    echo "NO_MODEL_CALL"
    echo "SCHEDULER_ACTIVATION=not_performed"
    echo "PERSISTENT_WORKER_ACTIVATION=not_performed"
    echo "REFUSE_E3V_RUNTIME_NOT_IMPLEMENTED_IN_STATIC_ARTIFACT"
    exit 2
    ;;
  --execute-approved)
    echo "MODE=execute-approved"
    if [ "${APPROVAL:-}" != "$REQUIRED_APPROVAL" ]; then
      echo "REFUSE_APPROVAL_MISSING"
      exit 2
    fi
    echo "APPROVAL_CAPTURED=$REQUIRED_APPROVAL"
    echo "REFUSE_E3V_RUNTIME_NOT_IMPLEMENTED_IN_STATIC_ARTIFACT"
    echo "NO_DB_WRITE"
    echo "NO_DB_CLAIM"
    echo "NO_ADAPTER_CALL"
    echo "NO_MODEL_CALL"
    exit 2
    ;;
  "")
    echo "REFUSE_MODE_REQUIRED"
    echo "EXPECTED_MODE=--dry-run or --execute-approved"
    exit 2
    ;;
  *)
    echo "REFUSE_UNKNOWN_MODE"
    echo "mode=$MODE"
    exit 2
    ;;
esac

# Future implementation contract only. Do not execute from this static artifact phase.
# Required future wrapper path:
#   ops/scheduler/stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh
# Required future smoke path:
#   ops/smoke/check-stage-16-e3v-run-one-existing-status-atomic-claim-dispatch.sh
#
# Required future approval:
#   APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY
#
# Required future pass marker:
#   E3V_OPTION_B_ATOMIC_CLAIM_ONE_SHOT_DISPATCH_OK
#
# Required future modes:
#   --dry-run
#   --execute-approved
#
# Required future runtime refusal markers:
#   REFUSE_APPROVAL_MISSING
#   REFUSE_REPO_CHECKPOINT_MISMATCH
#   REFUSE_REPO_DIRTY
#   REFUSE_SCHEDULER_ACTIVE
#   REFUSE_PERSISTENT_WORKERS_ACTIVE
#   REFUSE_CT101_NOT_STOPPED
#   REFUSE_PVESO_UNAVAILABLE
#   REFUSE_OLLAMA_NOT_LOCALHOST_ONLY
#   REFUSE_MODEL_MISSING
#   REFUSE_NO_ELIGIBLE_JOB
#   REFUSE_MULTIPLE_ELIGIBLE_JOBS
#   REFUSE_FORBIDDEN_JOB_ID
#   REFUSE_SELECTED_JOB_NOT_QUEUED
#   REFUSE_SELECTED_JOB_HAS_RESULT
#   REFUSE_ATOMIC_CLAIM_NOT_ONE
#   REFUSE_COMPLETION_NOT_ONE
#   REFUSE_E3V_RUNTIME_NOT_IMPLEMENTED_IN_STATIC_ARTIFACT
#
# Required forbidden job ids:
#   23
#   24
#   27
#   28
#
# Required future model allowlist:
#   qwen2.5:32b-instruct-q4_K_M
#
# Required future scheduler gate markers:
#   NO_DB_WRITE
#   DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
#   RUNTIME_CALLS=disabled
#   SCHEDULER_ACTIVATION=not_performed
#   PERSISTENT_WORKER_ACTIVATION=not_performed
#   DB_INTEGRITY=ok
#   ELIGIBLE_WOULD_CLAIM_COUNT=1
#   WOULD_CLAIM job_id=
#
# Required future atomic claim SQL shape:
#   BEGIN IMMEDIATE;
#   UPDATE jobs
#   SET status='running',
#       attempts=attempts+1,
#       updated_at=:now
#   WHERE id=:job_id
#     AND status='queued'
#     AND requested_model=:expected_model
#     AND NOT EXISTS (
#       SELECT 1 FROM job_results WHERE job_id=:job_id
#     );
#   SELECT changes();
#   COMMIT;
#
# Required future claim result:
#   changes() == 1
#   claim_changes=1
#   status=running
#
# Required future completion SQL shape:
#   BEGIN IMMEDIATE;
#   UPDATE jobs
#   SET status='completed',
#       last_error=NULL,
#       updated_at=:now
#   WHERE id=:job_id
#     AND status='running'
#     AND requested_model=:expected_model
#     AND NOT EXISTS (
#       SELECT 1 FROM job_results WHERE job_id=:job_id
#     );
#   INSERT INTO job_results(
#       job_id,
#       model,
#       response_text,
#       response_json,
#       error,
#       created_at,
#       updated_at
#   )
#   VALUES(
#       :job_id,
#       :model,
#       :response_text,
#       :response_json,
#       NULL,
#       :now,
#       :now
#   );
#   COMMIT;
#
# Required future completion result:
#   completion_changes=1
#   job_results_for_job_after=1
#   pveso_runner_count_after=0
#   ct101_status_after=stopped
#   ct101_onboot_after=0
#
# Required future PVESO guard:
#   derive PVESO from Tailscale status, not hardcoded pveso DNS
#   OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
#   OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
#   non-localhost 11434 listener count is 0
#   target model present
#   no model pull
#
# Required future CT101 guard:
#   CT101_STATUS=stopped
#   CT101_ONBOOT=0
#   never start CT101
#
# Required future timeout recovery classifications:
#   DO_NOT_RERUN
#   RUN_READ_ONLY_RECOVERY_FIRST
#   completed_with_one_result_do_not_rerun
#   running_zero_results_runner_active_do_not_rerun
#   running_zero_results_no_runner_manual_recovery_required
#   queued_zero_results_no_claim_new_approval_required
#   failed_zero_results_do_not_rerun_without_review
#   duplicate_result_failure_do_not_rerun
#   ambiguous_preserve_artifacts_do_not_rerun
