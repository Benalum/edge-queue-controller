# Stage 16 E3X-F — Final Small-Model Runtime Proof Closure, Read-Only

## Result

E3X-F closed the Stage 16 E3X small-model runtime proof with read-only DB and PVESO validation.

Final marker:

    E3X_F_FINAL_SMALL_MODEL_RUNTIME_PROOF_CLOSURE_READ_ONLY_OK

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: e25cb71
    Previous tag: controller-stage-16-e3x-e-r5-approved-small-model-timeout-safe-runtime-proof-job-31-2026-06-21
    Working tree: clean

## Completed proof

Job 31 completed successfully through the timeout-safe wrapper:

    job_id=31
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=stage16_e3x_small_model_timeout_safe_completion_smoke
    result_rows=1
    classification=completed_with_one_result

This proves the complete controlled one-job path:

    queued job -> atomic claim -> bounded PVESO Ollama call -> completion transaction -> one job_results row

## Prior failed proof jobs

Jobs 29 and 30 remain closed failed and must not be rerun:

    job 29: failed, attempts=1, result_rows=0
    job 30: failed, attempts=1, result_rows=0

## DB closure output

```text
E3X_F_DB_CLOSURE=begin
DB_INTEGRITY=ok
JOBS_TOTAL=30
JOB_RESULTS_TOTAL=11
DUPLICATE_JOB_RESULTS none
JOB_29_CLOSURE id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 updated_at=2026-06-21T19:46:39.173248Z
JOB_30_CLOSURE id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 updated_at=2026-06-21T20:04:30.088429Z
JOB31_CLOSURE id=31 status=completed attempts=1 model=qwen2.5:0.5b job_type=stage16_e3x_small_model_timeout_safe_completion_smoke result_rows=1 last_error=None updated_at=2026-06-21T20:31:54.727776Z
E3X_F_RUNNING_E3V_E3W_E3X_JOB_COUNT=0
E3X_F_QUEUED_E3V_E3W_E3X_JOB_COUNT=0
E3X_F_RUNTIME_PROOF_CLASSIFICATION=completed_with_one_result
E3X_F_DB_CLOSURE_OK
```

## PVESO closure output

```text
E3X_F_PVESO_CLOSURE=begin
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_COUNT=1
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_LINES_BEGIN
 590163  339134       01:13 Sl   /usr/local/bin/ollama runner --model /var/lib/vz/ollama/models/blobs/sha256-c5396e06af294bd101b30dce59131a76d2b773e76950acc870eda801d3ab0515 --port 46759
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_LINES_END
CT101_STATUS=stopped
CT101_ONBOOT=0
--- models visible to host Ollama ---
NAME                                 ID              SIZE      MODIFIED       
qwen2.5:0.5b                         a8b0c5157701    397 MB    18 minutes ago    
qwen2.5-coder:32b-instruct-q4_K_M    b92d6a0bd47e    19 GB     4 months ago      
qwen2.5:32b-instruct-q4_K_M          9f13ba1299af    19 GB     4 months ago      
E3X_F_SMALL_MODEL_VISIBLE_TO_HOST_OLLAMA=true
E3X_F_PVESO_CLOSURE_OK
```

## Safety boundary

E3X-F did not:

- write the DB
- insert a job
- claim a job
- change job status
- increment attempts
- insert job_results
- execute the wrapper
- call a model
- pull a model
- activate scheduler
- activate persistent workers
- start CT101
- kill any process
- mutate services, CTs, VMs, Cloudflare, or private storage

## Conclusion

Stage 16 E3X proves the first successful timeout-safe small-model completion path on PVESO using:

    qwen2.5:0.5b

This changes the next project blocker from "prove a model job can complete safely" to:

    integrate this proven path into controlled scheduler activation design without enabling persistent workers yet

## Recommended next phase

Recommended next phase:

    E3Y-A — scheduler integration readiness plan, no activation

E3Y-A should remain no-apply/read-only/design-only.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Do not rerun job 31 without a new explicit plan and approval.
