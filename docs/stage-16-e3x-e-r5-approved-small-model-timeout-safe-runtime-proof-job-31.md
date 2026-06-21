# Stage 16 E3X-E-R5 — Approved Small-Model Timeout-Safe Runtime Proof for Job 31

## Result

E3X-E-R5 ran the approved timeout-safe one-job runtime proof for fresh small-model job 31.

Runtime classification:

    E3X_E_R5_RUNTIME_CLASSIFICATION=completed_with_one_result

Final marker:

    E3X_E_R5_APPROVED_SMALL_MODEL_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_31_OK

## Approval

Explicit approval was provided and consumed:

    APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY

The wrapper approval shim accepted the phase-specific approval:

    E3X_E_R5_RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 9c66d28
    Previous tag: controller-stage-16-e3x-e-r4-commit-wrapper-approval-shim-and-clean-dry-run-no-runtime-2026-06-21
    Working tree: clean

## Runtime target

    job_id=31
    requested_model=qwen2.5:0.5b
    job_type=stage16_e3x_small_model_timeout_safe_completion_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## Safety boundary

E3X-E-R5 allowed exactly:

- one atomic claim for job 31
- one bounded PVESO Ollama generate call to qwen2.5:0.5b
- either one completion transaction or one guarded internal failure update

E3X-E-R5 did not:

- insert a job
- retry a job
- rerun a claimed job
- call a second model request
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- apply a schema migration
- mutate services, CTs, VMs, Cloudflare, or private storage

## Preflight

```text
E3X_E_R5_READONLY_PREFLIGHT=begin
DB_INTEGRITY_BEFORE=ok
JOBS_TOTAL_BEFORE=30
JOB_RESULTS_TOTAL_BEFORE=10
DUPLICATE_JOB_RESULTS_BEFORE none
JOB_29_PREFLIGHT id=29 status=failed attempts=1
JOB_30_PREFLIGHT id=30 status=failed attempts=1
JOB31_PREFLIGHT id=31 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:17:45.142703Z
E3X_E_R5_ELIGIBLE_SMALL_MODEL_JOB_COUNT_BEFORE=1
E3X_E_R5_READONLY_PREFLIGHT_OK
```

## Runtime output

```text
RUNTIME_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY
RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--run
RUN_DIR=/tmp/apc-e3x-e-r5-approved-small-model-runtime-job-31-20260621T203146Z
EXPECTED_JOB_ID=31
EXPECTED_MODEL=qwen2.5:0.5b
EXPECTED_JOB_TYPE=stage16_e3x_small_model_timeout_safe_completion_smoke
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
E3W_CANDIDATE_JOB id=31 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:17:45.142703Z
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
E3W_JOB_AFTER_CLAIM id=31 status=running attempts=1 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=0
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
```

## Runtime classification

```text
E3X_E_R5_CLASSIFICATION=completed_with_one_result
E3X_E_R5_WRAPPER_RUNTIME_EXIT_CODE=0
E3X_E_R5_RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true
E3X_E_R5_ATOMIC_CLAIM_MARKER_PRESENT=true
E3X_E_R5_WRAPPER_COMPLETION_MARKER_PRESENT=true
E3X_E_R5_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=false
```

## Postflight

```text
E3X_E_R5_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER=ok
JOBS_TOTAL_AFTER=30
JOB_RESULTS_TOTAL_AFTER=11
DUPLICATE_JOB_RESULTS_AFTER none
JOB31_POSTFLIGHT id=31 status=completed attempts=1 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=1 last_error=None updated_at=2026-06-21T20:31:54.727776Z
E3X_E_R5_RUNTIME_CLASSIFICATION=completed_with_one_result
E3X_E_R5_READONLY_POSTFLIGHT_OK
```

## DB stat check

    before=43798528 1782073065 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43802624 1782073914 /var/lib/edge-queue-controller/edge_queue.sqlite3

The DB stat changed during approved runtime, as expected.

## Timeout-safe proof conclusion

The key success condition is that job 31 did not remain running.

Postflight classification:

    completed_with_one_result

If completed, the wrapper inserted exactly one job_results row and marked job 31 completed.

If internally failed, the wrapper left job_results unchanged and marked job 31 failed itself.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Do not rerun job 31 without a new explicit plan and approval.
