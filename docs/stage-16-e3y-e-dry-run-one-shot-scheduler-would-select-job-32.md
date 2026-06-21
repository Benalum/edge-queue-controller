# Stage 16 E3Y-E — Dry-Run One-Shot Scheduler Would Select Job 32

## Result

E3Y-E ran the one-shot scheduler in dry-run mode and proved it would select job 32 without mutating the DB or calling a model.

Final marker:

    E3Y_E_DRY_RUN_ONE_SHOT_SCHEDULER_WOULD_SELECT_JOB_32_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 4ac1d7d
    Previous tag: controller-stage-16-e3y-d-implement-one-shot-scheduler-wrapper-no-run-2026-06-21
    Working tree: clean

## Dry-run target

    job_id=32
    requested_model=qwen2.5:0.5b
    job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## One-shot scheduler dry-run output

```text
=== Stage 16 E3Y one-shot scheduler dispatch ===
MODE=--dry-run
EXPECTED_JOB_ID=32
EXPECTED_MODEL=qwen2.5:0.5b
EXPECTED_JOB_TYPE=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
MODEL_TIMEOUT_SECONDS=45
WRAPPER_TOTAL_SECONDS=120
NUM_PREDICT=8
TEMPERATURE=0
NO_PERSISTENT_SCHEDULER_ACTIVATION
NO_PERSISTENT_WORKER_ACTIVATION
DO_NOT_RERUN_E3V_Q
DO_NOT_RETRY_JOB_29
DO_NOT_RERUN_JOB_30
DO_NOT_RERUN_JOB_31
E3Y_ONE_SHOT_SCHEDULER_DRY_RUN_ONLY
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--dry-run
RUN_DIR=/tmp/apc-e3w-timeout-safe-one-job-32-20260621T204057Z
EXPECTED_JOB_ID=32
EXPECTED_MODEL=qwen2.5:0.5b
EXPECTED_JOB_TYPE=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
MODEL_TIMEOUT_SECONDS=45
WRAPPER_TOTAL_SECONDS=120
NUM_PREDICT=8
TEMPERATURE=0
DO_NOT_RERUN_E3V_Q
DO_NOT_RETRY_JOB_29
E3W_TIMEOUT_SAFE_WRAPPER_DRY_RUN_ONLY

=== scheduler/persistent worker disabled preflight ===
SCHEDULER_OR_WORKER_UNIT_FILES_PRESENT=review_required
E3W_SCHEDULER_PERSISTENT_WORKER_PREFLIGHT_REVIEWED

=== CT203 read-only candidate preflight ===
E3W_READONLY_CANDIDATE_PREFLIGHT=begin
DB_INTEGRITY=ok
DUPLICATE_JOB_RESULTS none
E3W_CANDIDATE_JOB id=32 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:38:06.336398Z
E3W_EXPECTED_ELIGIBLE_JOB_COUNT=1
E3W_READONLY_CANDIDATE_PREFLIGHT_OK
E3W_READONLY_CANDIDATE_PREFLIGHT_OK

=== PVESO read-only runtime preflight ===
PVESO_PREFLIGHT=begin
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_ACTIVE_MODEL_CLIENT_OR_RUNNER_COUNT=0
CT101_STATUS=stopped
CT101_ONBOOT=0
E3W_PVESO_PREFLIGHT_OK
E3W_PVESO_PREFLIGHT_OK

WOULD_ATOMIC_CLAIM job_id=32 model=qwen2.5:0.5b
WOULD_USE_MODEL_TIMEOUT_SECONDS=45
WOULD_USE_WRAPPER_TOTAL_SECONDS=120
WOULD_USE_NUM_PREDICT=8
WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR
E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME
E3Y_ONE_SHOT_SCHEDULER_DRY_RUN_WOULD_SELECT_JOB id=32 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
E3Y_ONE_SHOT_SCHEDULER_DRY_RUN_NO_DB_WRITE_NO_MODEL_CALL
```

## DB stat check

    before=43802624 1782074286 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43802624 1782074286 /var/lib/edge-queue-controller/edge_queue.sqlite3

    E3Y_E_DB_STAT_UNCHANGED_DURING_DRY_RUN=true

## Postflight output

```text
E3Y_E_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER_DRY_RUN=ok
JOBS_TOTAL_AFTER_DRY_RUN=31
JOB_RESULTS_TOTAL_AFTER_DRY_RUN=11
JOB32_AFTER_DRY_RUN id=32 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:38:06.336398Z
E3Y_E_ELIGIBLE_SCHEDULER_SELECTED_JOB_COUNT_AFTER_DRY_RUN=1
E3Y_E_RUNNING_STAGE16_PROOF_JOB_COUNT_AFTER_DRY_RUN=0
E3Y_E_READONLY_POSTFLIGHT_OK
```

## Proof

The one-shot scheduler would select job 32:

    E3Y_ONE_SHOT_SCHEDULER_DRY_RUN_WOULD_SELECT_JOB id=32 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke

The delegated timeout-safe wrapper would atomically claim job 32 if run:

    WOULD_ATOMIC_CLAIM job_id=32 model=qwen2.5:0.5b

E3Y-E did not:

- write the DB
- claim job 32
- increment attempts
- insert job_results
- execute runtime path
- call a model
- activate scheduler
- activate persistent workers

## Next phase

Recommended next phase:

    E3Y-F — approved one-shot scheduler runtime proof for job 32

E3Y-F requires explicit approval because it will run exactly one scheduler one-shot invocation and one bounded model call.

Approval phrase:

    APPROVE_STAGE_16_E3Y_F_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Do not rerun job 31.

Use job 32 only for the approved E3Y scheduler one-shot proof path.
