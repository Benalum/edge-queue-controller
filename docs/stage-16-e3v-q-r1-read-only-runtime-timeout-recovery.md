# Stage 16 E3V-Q-R1 — Read-Only Runtime Timeout Recovery

## Result

E3V-Q timed out after preflight while invoking the approved runtime wrapper.

E3V-Q-R1 performed read-only recovery only.

Final recovery classification:

    RECOVERY_FINAL_CLASSIFICATION=running_zero_results_runner_active_do_not_rerun

Required rule:

    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

## Safety boundary

E3V-Q-R1 did not:

- execute the wrapper
- run execute-approved
- write the DB
- apply a schema migration
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- call the helper
- call the adapter
- call a model
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Repo checkpoint

Recovery checkpoint:

    HEAD/origin/main/remote: 2018fd8
    Previous tag: controller-stage-16-e3v-p-pre-runtime-dry-run-validation-result-2026-06-21
    Working tree before recovery: clean

## DB recovery

DB recovery output:

```text
E3V_Q_R1_READONLY_RECOVERY=begin
DB_INTEGRITY_RECOVERY=ok
JOBS_TOTAL_RECOVERY=28
JOB_RESULTS_TOTAL_RECOVERY=10
DUPLICATE_JOB_RESULTS_RECOVERY none
JOB29_RECOVERY id=29 status=running attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 last_error=None updated_at=2026-06-21T19:36:12.132461Z
RECOVERY_CLASSIFICATION=running_zero_results_check_runner_before_any_manual_recovery
DO_NOT_RERUN
RUN_READ_ONLY_RECOVERY_FIRST
E3V_Q_R1_READONLY_DB_RECOVERY_OK
```

## PVESO recovery

PVESO recovery output:

```text
PVESO_TAILSCALE_STATUS_LOOKUP=OK
OLLAMA_SERVICE_STATE=active
PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=1
PVESO_RUNNER_OR_ADAPTER_PROCESS_LINES_BEGIN
 574974  339134       02:51 /usr/local/bin/ollama runner --model /var/lib/vz/ollama/models/blobs/sha256-eabc98a9bcbfce7fd70f3e07de599f8fda98120fefed5881934161ede8bd1a41 --port 46237
PVESO_RUNNER_OR_ADAPTER_PROCESS_LINES_END
CT101_STATUS=stopped
CT101_ONBOOT=0
RECOVERY_PVESO_CLASSIFICATION=runner_or_adapter_process_active
```

## Runtime artifacts

Runtime artifact recovery output:

```text
RUNTIME_ARTIFACT_RECOVERY=begin
candidate_stdout=/tmp/apc-e3v-q-approved-runtime-job-29-stdout.txt
candidate_stderr=/tmp/apc-e3v-q-approved-runtime-job-29-stderr.txt
candidate_rc=/tmp/apc-e3v-q-approved-runtime-job-29-rc.txt

ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-stdout.txt size=2298 mtime=1782070572
--- START /tmp/apc-e3v-q-approved-runtime-job-29-stdout.txt ---
STAGE=stage-16-e3v-run-one-existing-status-atomic-claim-dispatch
MODE=execute-approved
RUN_DIR=/tmp/apc-e3v-q-approved-runtime-job-29-20260621T193605Z
RUNTIME_APPROVAL_CAPTURED=APPROVE_STAGE_16_E3V_Q_RUN_JOB_29_OPTION_B_ATOMIC_CLAIM_DISPATCH_ONLY
RUNTIME_SCOPE=job_id_29_only
repo_head=2018fd8
expected_head=2018fd8
repo_dirty=<clean>
REPO_PREFLIGHT_OK
SCHEDULER_ENV_START

SCHEDULER_ENV_END
SCHEDULER_WORKER_DISABLED_PREFLIGHT_OK
43798528 1782069550 /var/lib/edge-queue-controller/edge_queue.sqlite3
CT203_READONLY_CANDIDATE_CHECK=begin
DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
DB_INTEGRITY=ok
JOBS_TOTAL=28
JOB_RESULTS_TOTAL=10
DUPLICATE_JOB_RESULTS none
JOB29_PREFLIGHT id=29 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0
ELIGIBLE_CANDIDATE job_id=29 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M result_rows=0 created=2026-06-21T19:19:10.150538Z updated=2026-06-21T19:19:10.150565Z
E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
WOULD_ATOMIC_CLAIM job_id=29 model=qwen2.5:32b-instruct-q4_K_M result_rows=0
E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME
CT203_READONLY_CANDIDATE_CHECK_OK
DB_OPEN_MODE=sqlite_uri_mode_ro_immutable
DB_INTEGRITY=ok
DUPLICATE_JOB_RESULTS none
E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1
WOULD_ATOMIC_CLAIM job_id=29 model=qwen2.5:32b-instruct-q4_K_M result_rows=0
PVESO_TAILSCALE_STATUS_LOOKUP=OK
PVESO_PREFLIGHT=begin
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0
TARGET_MODEL_PRESENT=true
CT101_STATUS=stopped
CT101_ONBOOT=0
PVESO_PREFLIGHT_OK
PVESO_PREFLIGHT_OK
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0
TARGET_MODEL_PRESENT=true
CT101_STATUS=stopped
CT101_ONBOOT=0
E3V_Q_ATOMIC_CLAIM=begin
DB_INTEGRITY_BEFORE_CLAIM=ok
E3V_Q_JOB_BEFORE_CLAIM id=29 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M result_rows=0
E3V_Q_ATOMIC_CLAIM_CHANGES=1
E3V_Q_JOB_STATUS_AFTER_CLAIM=running
E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1
E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0
E3V_Q_ATOMIC_CLAIM_OK
E3V_Q_ATOMIC_CLAIM_CHANGES=1
E3V_Q_JOB_STATUS_AFTER_CLAIM=running
E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1
E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0
E3V_Q_ATOMIC_CLAIM_OK
--- END /tmp/apc-e3v-q-approved-runtime-job-29-stdout.txt ---

ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-stderr.txt size=0 mtime=1782070567
--- START /tmp/apc-e3v-q-approved-runtime-job-29-stderr.txt ---
--- END /tmp/apc-e3v-q-approved-runtime-job-29-stderr.txt ---

ARTIFACT_MISSING /tmp/apc-e3v-q-approved-runtime-job-29-rc.txt

ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-schema-preflight.txt size=450 mtime=1782070567
--- START /tmp/apc-e3v-q-approved-runtime-job-29-schema-preflight.txt ---
E3V_Q_READONLY_PREFLIGHT=begin
DB_INTEGRITY_PREFLIGHT=ok
JOBS_REQUIRED_COLUMNS_PRESENT=true
JOB_RESULTS_REQUIRED_COLUMNS_PRESENT=true
E3V_Q_JOBS_TOTAL_BEFORE=28
E3V_Q_JOB_RESULTS_TOTAL_BEFORE=10
DUPLICATE_JOB_RESULTS_BEFORE none
JOB29_PREFLIGHT id=29 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0
E3V_Q_ELIGIBLE_JOB_COUNT_PREFLIGHT=1
E3V_Q_READONLY_PREFLIGHT_OK
--- END /tmp/apc-e3v-q-approved-runtime-job-29-schema-preflight.txt ---

ARTIFACT_MISSING /tmp/apc-e3v-q-approved-runtime-job-29-postflight.txt

run_dirs:
2026-06-21T13:36:12.1253095310 /tmp/apc-e3v-q-approved-runtime-job-29-20260621T193605Z
RUNTIME_ARTIFACT_RECOVERY=end
```

## Next action

Do not rerun E3V-Q.

Use the final classification to choose the next recovery step.
