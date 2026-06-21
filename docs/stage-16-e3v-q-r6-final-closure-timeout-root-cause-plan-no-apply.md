# Stage 16 E3V-Q-R6 — Final Closure and Timeout Root-Cause Plan, No Apply

## Result

E3V-Q-R6 performed read-only final closure validation after the R5 manual failure recovery.

Final closure markers:

    E3V_Q_R6_JOB29_FAILED_CLOSED_OK
    E3V_Q_R6_DB_CLOSURE_OK

## Repo checkpoint

Before this no-apply phase:

    HEAD/origin/main/remote: 97673d3
    Previous tag: controller-stage-16-e3v-q-r5-mark-job-29-failed-after-timeout-no-result-2026-06-21
    Working tree: clean

## Safety boundary

E3V-Q-R6 did not:

- write the DB
- apply a schema migration
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- run execute-approved
- call the helper
- call the adapter
- call a model
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Final DB closure

Read-only DB closure output:

```text
E3V_Q_R6_DB_CLOSURE=begin
DB_INTEGRITY_R6=ok
JOBS_TOTAL_R6=28
JOB_RESULTS_TOTAL_R6=10
DUPLICATE_JOB_RESULTS_R6 none
JOB29_R6 id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 last_error=E3V-Q timeout recovery: job was atomically claimed, but the bridge timed out before model output or completion; no model_adapter_result and no job_result artifact existed during read-only recovery. updated_at=2026-06-21T19:46:39.173248Z
E3V_Q_R6_ELIGIBLE_FRESH_JOB_COUNT_EXCLUDING_29=0
E3V_Q_R6_JOB29_FAILED_CLOSED_OK
E3V_Q_R6_DB_CLOSURE_OK
```

Confirmed final job 29 state:

    status=failed
    attempts=1
    result_rows=0
    requested_model=qwen2.5:32b-instruct-q4_K_M
    last_error contains E3V-Q timeout recovery

Job 29 is closed and must not be rerun.

## Runtime artifact closure

Read-only runtime artifact closure output:

```text
E3V_Q_R6_ARTIFACT_CLOSURE=begin
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
RUN_DIR_ARTIFACT_PRESENT atomic_claim_result.txt size=313
RUN_DIR_ARTIFACT_PRESENT model_adapter_result.txt size=0
RUN_DIR_ARTIFACT_MISSING completion_result.txt
RUN_DIR_ARTIFACT_MISSING final_status.txt
ATOMIC_CLAIM_ARTIFACT_STATUS=claim_success_artifact_present
MODEL_ARTIFACT_STATUS=missing_or_empty
COMPLETION_ARTIFACT_STATUS=missing_or_empty
FINAL_STATUS_ARTIFACT_STATUS=missing_or_empty
E3V_Q_R6_ARTIFACT_CLOSURE=end
```

The runtime artifact pattern confirms:

    atomic claim artifact present
    model adapter result missing or empty
    completion result missing or empty
    final status missing or empty

## Root-cause conclusion

E3V-Q proved the atomic DB claim path works.

The failure occurred after successful claim and before model adapter completion.

The likely root cause is outer PPB/tmux runtime timeout or interruption while the wrapper was waiting for the PVESO Ollama generation. The wrapper's own model timeout was longer than the bridge/runtime execution window, so the outer runner could interrupt after claim and before the wrapper could either complete or fail the job itself.

## Required prevention before next runtime attempt

Before another runtime dispatch attempt, implement a no-apply fix plan that prevents "claimed but externally killed before completion" from becoming the normal failure mode.

The next implementation plan should include at least one of these protections:

1. Make the wrapper's model-call timeout shorter than the PPB/outer execution timeout, so the wrapper can catch timeout and mark the job failed inside its own transaction.
2. Use a smaller/known-fast model for the next one-job runtime proof.
3. Add a pre-approved stuck-running recovery path that is part of the runtime playbook, not improvised after timeout.
4. Add a lease/heartbeat field or recovery classification for running jobs if the schema supports it in a later stage.
5. Avoid any second model call or retry for an already-claimed job unless a new job is inserted and separately approved.

## Recommended next phase

Recommended next phase:

    Stage 16 E3W-A — runtime timeout prevention design, no apply

E3W-A should plan a safer next proof using:

    new job id, not job 29
    shorter model timeout
    smaller model or lower num_predict
    explicit wrapper timeout less than PPB timeout
    same atomic-claim guard pattern
    same no-rerun recovery discipline

## Hard rule

Do not rerun E3V-Q.

Do not retry job 29.

Job 29 is closed as failed.
