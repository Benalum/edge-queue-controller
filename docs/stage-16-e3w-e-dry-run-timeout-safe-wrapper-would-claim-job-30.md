# Stage 16 E3W-E — Dry-Run Timeout-Safe Wrapper Would Claim Job 30

## Result

E3W-E ran the timeout-safe wrapper in dry-run mode only.

The wrapper would claim exactly job 30.

Final marker:

    E3W_E_DRY_RUN_TIMEOUT_SAFE_WRAPPER_WOULD_CLAIM_JOB_30_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: ceb5b60
    Previous tag: controller-stage-16-e3w-d-insert-one-fresh-timeout-safe-proof-job-2026-06-21
    Working tree: clean

## Dry-run target

    job_id=30
    requested_model=qwen2.5:32b-instruct-q4_K_M
    job_type=stage16_e3w_timeout_safe_one_job_model_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## Safety boundary

E3W-E did not:

- write the DB
- apply a schema migration
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper in runtime mode
- run execute-approved
- call the helper
- call the adapter
- call a model
- call prompt/completion/generate/chat/embed
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Wrapper dry-run output

```text
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--dry-run
RUN_DIR=/tmp/apc-e3w-timeout-safe-one-job-30-20260621T200127Z
EXPECTED_JOB_ID=30
EXPECTED_MODEL=qwen2.5:32b-instruct-q4_K_M
EXPECTED_JOB_TYPE=stage16_e3w_timeout_safe_one_job_model_smoke
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

WOULD_ATOMIC_CLAIM job_id=30 model=qwen2.5:32b-instruct-q4_K_M
WOULD_USE_MODEL_TIMEOUT_SECONDS=45
WOULD_USE_WRAPPER_TOTAL_SECONDS=120
WOULD_USE_NUM_PREDICT=8
WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR
E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME
```

## DB unchanged check

    before=43798528 1782071990 /var/lib/edge-queue-controller/edge_queue.sqlite3
    after=43798528 1782071990 /var/lib/edge-queue-controller/edge_queue.sqlite3
    E3W_E_DB_STAT_UNCHANGED_DURING_DRY_RUN=true

## Read-only postflight

```text
E3W_E_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER_DRY_RUN=ok
JOB30_AFTER_DRY_RUN id=30 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 last_error=None updated_at=2026-06-21T19:59:50.942151Z
E3W_E_ELIGIBLE_MATCHING_JOB_COUNT_AFTER_DRY_RUN=1
E3W_E_READONLY_POSTFLIGHT_OK
```

## Dry-run conclusion

The wrapper dry-run proved:

    E3W_READONLY_CANDIDATE_PREFLIGHT_OK
    E3W_CANDIDATE_JOB id=30 status=queued attempts=0
    E3W_EXPECTED_ELIGIBLE_JOB_COUNT=1
    E3W_PVESO_PREFLIGHT_OK
    WOULD_ATOMIC_CLAIM job_id=30 model=qwen2.5:32b-instruct-q4_K_M
    WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR
    E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME

Job 30 remained unchanged:

    status=queued
    attempts=0
    result_rows=0

## Next phase

Recommended next phase:

    E3W-F — approved timeout-safe one-job runtime proof for job 30

E3W-F requires explicit approval because it will perform a real atomic claim and one model call.

Expected approval phrase:

    APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not run E3W-F without explicit approval.
