# Stage 16 E3W-F — Approved Timeout-Safe Runtime Proof for Job 30

## Result

E3W-F ran the approved timeout-safe one-job runtime proof for job 30.

Runtime classification:

    E3W_F_RUNTIME_CLASSIFICATION=internal_failure_no_result

Final marker:

    E3W_F_APPROVED_TIMEOUT_SAFE_RUNTIME_PROOF_JOB_30_OK

## Approval

Explicit approval was provided:

    APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: b61d606
    Previous tag: controller-stage-16-e3w-e-dry-run-timeout-safe-wrapper-would-claim-job-30-2026-06-21
    Working tree: clean

## Runtime target

    job_id=30
    requested_model=qwen2.5:32b-instruct-q4_K_M
    job_type=stage16_e3w_timeout_safe_one_job_model_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## Safety boundary

E3W-F allowed exactly:

- one atomic claim for job 30
- one bounded PVESO Ollama generate call
- either one completion transaction or one guarded internal failure update

E3W-F did not:

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
E3W_F_READONLY_PREFLIGHT=begin
DB_INTEGRITY_BEFORE=ok
JOBS_TOTAL_BEFORE=29
JOB_RESULTS_TOTAL_BEFORE=10
DUPLICATE_JOB_RESULTS_BEFORE none
JOB29_PREFLIGHT id=29 status=failed attempts=1
JOB30_PREFLIGHT id=30 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 last_error=None updated_at=2026-06-21T19:59:50.942151Z
E3W_F_ELIGIBLE_MATCHING_JOB_COUNT_BEFORE=1
E3W_F_READONLY_PREFLIGHT_OK
```

## Runtime output

```text
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--run
RUN_DIR=/tmp/apc-e3w-f-approved-runtime-job-30-20260621T200337Z
EXPECTED_JOB_ID=30
EXPECTED_MODEL=qwen2.5:32b-instruct-q4_K_M
EXPECTED_JOB_TYPE=stage16_e3w_timeout_safe_one_job_model_smoke
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
E3W_CANDIDATE_JOB id=30 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 last_error=None updated_at=2026-06-21T19:59:50.942151Z
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
E3W_JOB_AFTER_CLAIM id=30 status=running attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0
E3W_RUNTIME_ATOMIC_CLAIM_OK
E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1
E3W_RUNTIME_ATOMIC_CLAIM_OK

=== one model call with bounded timeout ===
E3W_ONE_SHOT_MODEL_RESULT=error
E3W_ONE_SHOT_MODEL_ERROR=TimeoutError: timed out
=== guarded internal failure update ===
E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1
E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_OK
E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1
E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK
```

## Runtime classification

```text
E3W_F_CLASSIFICATION=internal_failure_no_result
E3W_F_WRAPPER_RUNTIME_EXIT_CODE=0
E3W_F_WRAPPER_COMPLETION_MARKER_PRESENT=false
E3W_F_WRAPPER_INTERNAL_FAILURE_MARKER_PRESENT=true
E3W_F_ATOMIC_CLAIM_MARKER_PRESENT=true
```

## Postflight

```text
E3W_F_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER=ok
JOBS_TOTAL_AFTER=29
JOB_RESULTS_TOTAL_AFTER=10
DUPLICATE_JOB_RESULTS_AFTER none
JOB30_POSTFLIGHT id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 last_error=E3W timeout-safe wrapper: model call timed out or failed before completion; job was marked failed internally. updated_at=2026-06-21T20:04:30.088429Z
E3W_F_RUNTIME_CLASSIFICATION=internal_failure_no_result
E3W_F_READONLY_POSTFLIGHT_OK
```

## DB stat check

    before=43798528 1782071990 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782072270 /var/lib/edge-queue-controller/edge_queue.sqlite3

The DB stat changed during approved runtime, as expected.

## Timeout-safe proof conclusion

The key success condition is that job 30 did not remain running.

Postflight classification:

    internal_failure_no_result

If completed, the wrapper inserted exactly one job_results row and marked job 30 completed.

If internally failed, the wrapper left job_results unchanged and marked job 30 failed itself.

In either case, the timeout-safe wrapper avoided the E3V-Q failure mode of leaving a claimed job stuck running without a result.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30 without a new explicit plan and approval.
