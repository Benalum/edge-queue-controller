# Stage 16 E3X-E-R4 — Commit Wrapper Approval Shim and Clean Dry-Run, No Runtime

## Result

E3X-E-R4 recovered from the R3 dirty-repo refusal. R3 inserted the approval compatibility shim successfully, but the wrapper refused the post-patch dry-run because the repo was dirty.

E3X-E-R4 validates the existing shim, commits it, then runs the dry-run after the repo is clean.

Final marker:

    E3X_E_R4_COMMIT_WRAPPER_APPROVAL_SHIM_AND_CLEAN_DRY_RUN_NO_RUNTIME_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: d2f698c
    Previous tag: controller-stage-16-e3x-d-dry-run-timeout-safe-wrapper-would-claim-job-31-2026-06-21
    Dirty state: exactly modified wrapper from failed R3

## DB recovery output

```text
E3X_E_R4_DB_RECOVERY=begin
DB_INTEGRITY=ok
JOB31_RECOVERY_STATE id=31 status=queued attempts=0 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=0 last_error=None updated_at=2026-06-21T20:17:45.142703Z
E3X_E_R4_ELIGIBLE_SMALL_MODEL_JOB_COUNT=1
E3X_E_R4_DB_RECOVERY_OK
```

## Wrapper shim validation

```text
E3X_E_R4_WRAPPER_SHIM_VALIDATION=begin
4:# E3X_E_APPROVAL_COMPAT_SHIM_BEGIN
8:# E3W_REQUIRED_APPROVAL exactly matches E3W_APPROVAL.
9:if [ -n "${E3W_REQUIRED_APPROVAL:-}" ]; then
10:  case "$E3W_REQUIRED_APPROVAL" in
12:      echo "RUNTIME_REQUIRED_APPROVAL=$E3W_REQUIRED_APPROVAL"
13:      if [ "${E3W_APPROVAL:-}" = "$E3W_REQUIRED_APPROVAL" ]; then
16:        echo "RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true"
11:    "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"|"APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY")
11:    "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"|"APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY")
14:        E3W_APPROVAL="APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"
30:REQUIRED_APPROVAL="APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"
E3X_E_R4_WRAPPER_SHIM_VALIDATION_OK
```

## Patch behavior

The wrapper now supports this safe runtime pairing:

    E3W_REQUIRED_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY
    E3W_APPROVAL=APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY

The shim maps internally to the existing wrapper gate:

    APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY

Allowed required approval values are explicitly whitelisted.

## Safety boundary

E3X-E-R4 did not:

- write the DB
- claim job 31
- increment attempts
- insert job_results
- execute runtime path
- call a model
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Post-commit dry-run

The post-commit dry-run output is appended below after commit.

## Next phase

Recommended next phase:

    E3X-E-R5 — approved small-model timeout-safe runtime proof for job 31

Use the same explicit approval phrase already provided:

    APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Use job 31 only for the approved small-model completion proof path.

## Clean repo dry-run after commit

```text
=== Stage 16 E3W timeout-safe one-job dispatch wrapper ===
MODE=--dry-run
RUN_DIR=/tmp/apc-e3w-timeout-safe-one-job-31-20260621T203031Z
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

    E3X_E_R4_DB_STAT_UNCHANGED_AFTER_CLEAN_DRY_RUN=true
