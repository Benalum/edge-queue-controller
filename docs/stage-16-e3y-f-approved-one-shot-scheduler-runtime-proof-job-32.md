# Stage 16 E3Y-F — Approved One-Shot Scheduler Runtime Proof for Job 32

## Result

E3Y-F ran the approved one-shot scheduler runtime proof for job 32.

Runtime classification:

    E3Y_F_RUNTIME_CLASSIFICATION=completed_with_one_result

Final marker:

    E3Y_F_APPROVED_ONE_SHOT_SCHEDULER_RUNTIME_PROOF_JOB_32_OK

## Approval

Explicit approval was provided and consumed:

    APPROVE_STAGE_16_E3Y_F_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY

The one-shot scheduler accepted approval:

    E3Y_F_SCHEDULER_APPROVAL_ACCEPTED=true

The one-shot scheduler delegated to the timeout-safe wrapper:

    E3Y_F_SCHEDULER_DELEGATION_MARKER_PRESENT=true

The timeout-safe wrapper accepted its internal approval shim:

    E3Y_F_WRAPPER_APPROVAL_OVERRIDE_ACCEPTED=true

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 1ed6e5d
    Previous tag: controller-stage-16-e3y-e-dry-run-one-shot-scheduler-would-select-job-32-2026-06-21
    Working tree: clean

## Runtime target

    job_id=32
    requested_model=qwen2.5:0.5b
    job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## Safety boundary

E3Y-F allowed exactly:

- one scheduler one-shot invocation
- one timeout-safe wrapper delegation
- one atomic claim for job 32
- one bounded PVESO Ollama generate call to qwen2.5:0.5b
- either one completion transaction or one guarded internal failure update

E3Y-F did not:

- insert a job
- retry a job
- rerun job 32
- call a second model request
- activate persistent scheduler service
- activate persistent workers
- pull a model
- start CT101
- kill any process
- apply a schema migration
- mutate services, CTs, VMs, Cloudflare, or private storage

## Preflight

```text
E3Y_F_READONLY_PREFLIGHT=begin
DB_INTEGRITY_BEFORE=ok
JOBS_TOTAL_BEFORE=31
JOB_RESULTS_TOTAL_BEFORE=11
DUPLICATE_JOB_RESULTS_BEFORE none
JOB_29_PREFLIGHT id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 updated_at=2026-06-21T19:46:39.173248Z
JOB_30_PREFLIGHT id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 updated_at=2026-06-21T20:04:30.088429Z
JOB_31_PREFLIGHT id=31 status=completed attempts=1 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=1 updated_at=2026-06-21T20:31:54.727776Z
JOB_32_PREFLIGHT id=32 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke result_rows=0 updated_at=2026-06-21T20:38:06.336398Z
E3Y_F_ELIGIBLE_SCHEDULER_SELECTED_JOB_COUNT_BEFORE=1
E3Y_F_RUNNING_STAGE16_PROOF_JOB_COUNT_BEFORE=0
E3Y_F_READONLY_PREFLIGHT_OK
```

## Runtime output

```text
=== Stage 16 E3Y one-shot scheduler dispatch ===
MODE=--run
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
E3Y_ONE_SHOT_SCHEDULER_RUN_MODE_APPROVAL_REQUIRED=APPROVE_STAGE_16_E3Y_F_RUN_ONE_SHOT_SCHEDULER_SMALL_MODEL_JOB_ONLY
E3Y_ONE_SHOT_SCHEDULER_APPROVAL_ACCEPTED=true
E3Y_ONE_SHOT_SCHEDULER_DELEGATING_TO_TIMEOUT_SAFE_WRAPPER=true
RUNTIME_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY
RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--run
RUN_DIR=/tmp/apc-e3w-timeout-safe-one-job-32-20260621T204252Z
EXPECTED_JOB_ID=32
EXPECTED_MODEL=qwen2.5:0.5b
EXPECTED_JOB_TYPE=stage16_e3y_scheduler_one_shot_small_model_completion_smoke
MODEL_TIMEOUT_SECONDS=45
WRAPPER_TOTAL_SECONDS=120
NUM_PREDICT=8
TEMPERATURE=0
DO_NOT_RERUN_E3V_Q
DO_NOT_RETRY_JOB_29

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

=== atomic claim ===
E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1
E3W_JOB_AFTER_CLAIM id=32 status=running attempts=1 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke result_rows=0
E3W_RUNTIME_ATOMIC_CLAIM_OK
E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1
E3W_RUNTIME_ATOMIC_CLAIM_OK

=== one model call with bounded timeout ===
E3W_ONE_SHOT_MODEL_RESULT=ok
E3W_ONE_SHOT_MODEL_RESPONSE_BEGIN
E3W_TIMEOUT_SAFE_OK
E3W_ONE_SHOT_MODEL_RESPONSE_END

=== completion transaction ===
E3W_COMPLETION_JOB_UPDATE_CHANGES=1
E3W_COMPLETION_RESULT_ROWS_AFTER=1
E3W_RUNTIME_COMPLETION_OK
E3W_RUNTIME_COMPLETION_OK
E3W_TIMEOUT_SAFE_RUNTIME_DONE
E3Y_ONE_SHOT_SCHEDULER_RUNTIME_DELEGATION_DONE
```

## Runtime classification

```text
E3Y_F_CLASSIFICATION=completed_with_one_result
E3Y_F_ONE_SHOT_SCHEDULER_RUNTIME_EXIT_CODE=0
E3Y_F_SCHEDULER_APPROVAL_ACCEPTED=true
E3Y_F_SCHEDULER_DELEGATION_MARKER_PRESENT=true
E3Y_F_WRAPPER_APPROVAL_OVERRIDE_ACCEPTED=true
E3Y_F_ATOMIC_CLAIM_MARKER_PRESENT=true
E3Y_F_WRAPPER_COMPLETION_MARKER_PRESENT=true
E3Y_F_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=false
E3Y_F_SCHEDULER_RUNTIME_DELEGATION_DONE_MARKER_PRESENT=true
```

## Postflight

```text
E3Y_F_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER=ok
JOBS_TOTAL_AFTER=31
JOB_RESULTS_TOTAL_AFTER=12
DUPLICATE_JOB_RESULTS_AFTER none
JOB32_POSTFLIGHT id=32 status=completed attempts=1 model=qwen2.5:0.5b job_type=stage16_e3y_scheduler_one_shot_small_model_completion_smoke result_rows=1 last_error=None updated_at=2026-06-21T20:42:58.627597Z
E3Y_F_RUNTIME_CLASSIFICATION=completed_with_one_result
E3Y_F_RUNNING_STAGE16_PROOF_JOB_COUNT_AFTER=0
E3Y_F_READONLY_POSTFLIGHT_OK
```

## DB stat check

    before=43802624 1782074286 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43802624 1782074578 /var/lib/edge-queue-controller/edge_queue.sqlite3

The DB stat changed during approved runtime, as expected.

## Proof conclusion

E3Y-F proves the manually invoked scheduler one-shot path can safely delegate one eligible job to the timeout-safe wrapper.

Postflight classification:

    completed_with_one_result

If completed, the wrapper inserted exactly one job_results row and marked job 32 completed.

If internally failed, the wrapper left job_results unchanged and marked job 32 failed itself.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Do not rerun job 31.

Do not rerun job 32 without a new explicit plan and approval.
