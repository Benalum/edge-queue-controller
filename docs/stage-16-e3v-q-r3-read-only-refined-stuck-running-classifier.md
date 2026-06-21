# Stage 16 E3V-Q-R3 — Read-Only Refined Stuck-Running Classifier

## Result

E3V-Q-R3 refined the E3V-Q timeout recovery classification.

Final R3 classification:

    RECOVERY_R3_FINAL_CLASSIFICATION=running_zero_results_no_runner_no_artifact_manual_failure_plan_required

Required rule:

    DO_NOT_RERUN
    RUN_READ_ONLY_RECOVERY_FIRST

## Safety boundary

E3V-Q-R3 did not:

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

## DB read-only output

```text
E3V_Q_R3_DB_READONLY=begin
DB_INTEGRITY_R3=ok
JOBS_TOTAL_R3=28
JOB_RESULTS_TOTAL_R3=10
DUPLICATE_JOB_RESULTS_R3 none
JOB29_R3 id=29 status=running attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 last_error=None updated_at=2026-06-21T19:36:12.132461Z
DB_CLASSIFICATION_R3=running_zero_results_needs_refined_activity_check
DO_NOT_RERUN
RUN_READ_ONLY_RECOVERY_FIRST
E3V_Q_R3_DB_READONLY_OK
```

## PVESO refined read-only output

```text
PVESO_TAILSCALE_STATUS_LOOKUP=OK
OLLAMA_SERVICE_STATE=active
PVESO_REFINED_PROCESS_SNAPSHOT_BEGIN
PVESO_REFINED_PROCESS_SNAPSHOT_END
PVESO_REFINED_ACTIVE_CLIENT_COUNT=0
PVESO_REFINED_RUNNER_PROCESS_COUNT=0
PVESO_REFINED_OLLAMA_11434_CONNECTION_LINES_BEGIN

PVESO_REFINED_OLLAMA_11434_CONNECTION_LINES_END
PVESO_REFINED_OLLAMA_11434_CONNECTION_COUNT=0
CT101_STATUS_R3=stopped
CT101_ONBOOT_R3=0
PVESO_REFINED_ACTIVITY_CLASSIFICATION=no_runner_no_active_client_or_connection
```

## Runtime artifact refined output

```text
RUNTIME_ARTIFACT_R3=begin
LATEST_E3V_Q_RUN_DIR=/tmp/apc-e3v-q-approved-runtime-job-29-20260621T193605Z
LATEST_RUN_DIR_FILE_LIST_BEGIN
atomic_claim_job_29.py size=3393 mtime=1782070571.2153361570
atomic_claim_result.txt size=313 mtime=1782070572.1053101160
ct203_db_stat_before.txt size=70 mtime=1782070568.7084095630
ct203_readonly_candidate_check.py size=4111 mtime=1782070568.7114094750
ct203_readonly_candidate_check.txt size=681 mtime=1782070569.5723842550
e3v_q_do_not_rerun_recovery_hint.txt size=737 mtime=1782070565.9634900350
model_adapter_result.txt size=0 mtime=1782070572.1253095310
pveso_ip.txt size=13 mtime=1782070571.2133362150
pveso_ollama_generate_job_29.py size=1233 mtime=1782070572.1233095900
pveso_preflight.txt size=287 mtime=1782070571.1973366840
recovery_hint.txt size=697 mtime=1782070567.8474347930
repo_preflight.txt size=59 mtime=1782070567.8634343240
scheduler_worker_disabled_preflight.txt size=78 mtime=1782070567.8774339130
LATEST_RUN_DIR_FILE_LIST_END
RUN_DIR_ARTIFACT_PRESENT recovery_hint.txt size=697
--- START recovery_hint.txt ---
DO_NOT_RERUN
RUN_READ_ONLY_RECOVERY_FIRST
stage=stage-16-e3v-run-one-existing-status-atomic-claim-dispatch
mode=--execute-approved
run_dir=/tmp/apc-e3v-q-approved-runtime-job-29-20260621T193605Z
fresh_job_id=29
expected_model=qwen2.5:32b-instruct-q4_K_M
runtime_approval=APPROVE_STAGE_16_E3V_Q_RUN_JOB_29_OPTION_B_ATOMIC_CLAIM_DISPATCH_ONLY
timeout_recovery_classifications:
completed_with_one_result_do_not_rerun
running_zero_results_runner_active_do_not_rerun
running_zero_results_no_runner_manual_recovery_required
queued_zero_results_no_claim_new_approval_required
failed_zero_results_do_not_rerun_without_review
duplicate_result_failure_do_not_rerun
ambiguous_preserve_artifacts_do_not_rerun
--- END recovery_hint.txt ---

RUN_DIR_ARTIFACT_PRESENT repo_preflight.txt size=59
--- START repo_preflight.txt ---
repo_head=2018fd8
expected_head=2018fd8
repo_dirty=<clean>
--- END repo_preflight.txt ---

RUN_DIR_ARTIFACT_PRESENT scheduler_worker_disabled_preflight.txt size=78
--- START scheduler_worker_disabled_preflight.txt ---
SCHEDULER_ENV_START

SCHEDULER_ENV_END
SCHEDULER_WORKER_DISABLED_PREFLIGHT_OK
--- END scheduler_worker_disabled_preflight.txt ---

RUN_DIR_ARTIFACT_PRESENT ct203_db_stat_before.txt size=70
--- START ct203_db_stat_before.txt ---
43798528 1782069550 /var/lib/edge-queue-controller/edge_queue.sqlite3
--- END ct203_db_stat_before.txt ---

RUN_DIR_ARTIFACT_PRESENT ct203_readonly_candidate_check.txt size=681
--- START ct203_readonly_candidate_check.txt ---
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
--- END ct203_readonly_candidate_check.txt ---

RUN_DIR_ARTIFACT_PRESENT pveso_preflight.txt size=287
--- START pveso_preflight.txt ---
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
--- END pveso_preflight.txt ---

RUN_DIR_ARTIFACT_PRESENT atomic_claim_result.txt size=313
--- START atomic_claim_result.txt ---
E3V_Q_ATOMIC_CLAIM=begin
DB_INTEGRITY_BEFORE_CLAIM=ok
E3V_Q_JOB_BEFORE_CLAIM id=29 status=queued attempts=0 model=qwen2.5:32b-instruct-q4_K_M result_rows=0
E3V_Q_ATOMIC_CLAIM_CHANGES=1
E3V_Q_JOB_STATUS_AFTER_CLAIM=running
E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1
E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0
E3V_Q_ATOMIC_CLAIM_OK
--- END atomic_claim_result.txt ---

RUN_DIR_ARTIFACT_PRESENT model_adapter_result.txt size=0
--- START model_adapter_result.txt ---
--- END model_adapter_result.txt ---

RUN_DIR_ARTIFACT_MISSING completion_result.txt

RUN_DIR_ARTIFACT_MISSING postflight_pveso_ct101.txt

RUN_DIR_ARTIFACT_MISSING ct203_db_stat_after.txt

RUN_DIR_ARTIFACT_MISSING final_status.txt

TOP_LEVEL_ARTIFACTS_BEGIN
TOP_ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-stdout.txt size=2298 mtime=1782070572
TOP_ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-stderr.txt size=0 mtime=1782070567
TOP_ARTIFACT_MISSING /tmp/apc-e3v-q-approved-runtime-job-29-rc.txt
TOP_ARTIFACT_PRESENT /tmp/apc-e3v-q-approved-runtime-job-29-schema-preflight.txt size=450 mtime=1782070567
TOP_ARTIFACT_MISSING /tmp/apc-e3v-q-approved-runtime-job-29-postflight.txt
TOP_LEVEL_ARTIFACTS_END
MODEL_ARTIFACT_CLASSIFICATION=model_adapter_result_missing
COMPLETION_ARTIFACT_CLASSIFICATION=completion_result_missing
RUNTIME_ARTIFACT_R3=end
```

## Interpretation

Do not rerun E3V-Q.

If job 29 remains running with zero results and no active client/connection, the next phase must be a no-apply manual recovery plan for job 29.

The manual recovery plan must not claim the job again.
