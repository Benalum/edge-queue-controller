# Stage 16 E3X-D — Dry-Run Timeout-Safe Wrapper Would Claim Job 31

## Result

E3X-D ran the timeout-safe wrapper in dry-run mode against the fresh small-model proof job.

Final marker:

    E3X_D_DRY_RUN_TIMEOUT_SAFE_WRAPPER_WOULD_CLAIM_JOB_31_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: 9d510f8
    Previous tag: controller-stage-16-e3x-c-insert-one-fresh-small-model-proof-job-2026-06-21
    Working tree: clean

## Dry-run target

    job_id=31
    requested_model=qwen2.5:0.5b
    job_type=stage16_e3x_small_model_timeout_safe_completion_smoke
    model_timeout_seconds=45
    wrapper_total_seconds=120
    num_predict=8
    temperature=0

## Dry-run proof

The wrapper would atomically claim job 31:

    WOULD_ATOMIC_CLAIM job_id=31 model=qwen2.5:0.5b

The dry-run did not:

- write the DB
- claim the job
- increment attempts
- insert job_results
- call a model
- execute runtime path

DB stat unchanged:

    E3X_D_DB_STAT_UNCHANGED_DURING_DRY_RUN=true

## Wrapper dry-run output

```text
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--dry-run
RUN_DIR=/tmp/apc-e3w-timeout-safe-one-job-31-20260621T201845Z
EXPECTED_JOB_ID=31
EXPECTED_MODEL=qwen2.5:0.5b
EXPECTED_JOB_TYPE=stage16_e3x_small_model_timeout_safe_completion_smoke
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

WOULD_ATOMIC_CLAIM job_id=31 model=qwen2.5:0.5b
WOULD_USE_MODEL_TIMEOUT_SECONDS=45
WOULD_USE_WRAPPER_TOTAL_SECONDS=120
WOULD_USE_NUM_PREDICT=8
WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR
E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME
```

## Postflight output

```text
E3X_D_READONLY_POSTFLIGHT=begin
DB_INTEGRITY_AFTER_DRY_RUN=ok
JOB31_AFTER_DRY_RUN id=31 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:17:45.142703Z
E3X_D_ELIGIBLE_SMALL_MODEL_JOB_COUNT_AFTER_DRY_RUN=1
E3X_D_READONLY_POSTFLIGHT_OK
```

## Next phase

Recommended next phase:

    E3X-E — approved timeout-safe runtime completion proof for job 31

E3X-E requires explicit approval because it will claim job 31 and make one bounded model call.

Approval phrase:

    APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Use job 31 only for the approved small-model completion proof path.
