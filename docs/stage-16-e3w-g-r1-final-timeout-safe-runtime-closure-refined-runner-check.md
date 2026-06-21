# Stage 16 E3W-G-R1 — Final Timeout-Safe Runtime Closure with Refined Runner Check

## Result

E3W-G-R1 completed the final read-only closure checkpoint for the E3W timeout-safe runtime proof.

Final marker:

    E3W_G_R1_FINAL_TIMEOUT_SAFE_RUNTIME_CLOSURE_OK

PVESO runner classification:

    E3W_G_R1_PVESO_RUNNER_CLASSIFICATION=idle_or_loaded_runner_present_no_active_client

## Repo checkpoint

Before this phase:

    HEAD/origin/main/remote: fc48c23
    Previous tag: controller-stage-16-e3w-f-approved-timeout-safe-runtime-proof-job-30-2026-06-21
    Working tree: clean

## Closure summary

E3W-F proved the timeout-safe wrapper fixes the E3V-Q failure mode.

Job 30 was atomically claimed, the 32B model call timed out, and the wrapper internally marked job 30 failed. Job 30 did not remain running.

Key final state:

    job_29=status=failed attempts=1 result_rows=0
    job_30=status=failed attempts=1 result_rows=0
    job_results_total=10
    running_e3v_e3w_jobs=0
    eligible_e3v_e3w_jobs=0
    active_model_clients=0
    pveso_runner_classification=idle_or_loaded_runner_present_no_active_client

## DB closure output

```text
E3W_G_R1_DB_CLOSURE=begin
DB_INTEGRITY=ok
JOBS_TOTAL=29
JOB_RESULTS_TOTAL=10
DUPLICATE_JOB_RESULTS none
JOB_29_CLOSURE id=29 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3v_option_b_atomic_claim_fresh_model_smoke result_rows=0 last_error=E3V-Q timeout recovery: job was atomically claimed, but the bridge timed out before model output or completion; no model_adapter_result and no job_result artifact existed during read-only recovery. updated_at=2026-06-21T19:46:39.173248Z
JOB_30_CLOSURE id=30 status=failed attempts=1 model=qwen2.5:32b-instruct-q4_K_M job_type=stage16_e3w_timeout_safe_one_job_model_smoke result_rows=0 last_error=E3W timeout-safe wrapper: model call timed out or failed before completion; job was marked failed internally. updated_at=2026-06-21T20:04:30.088429Z
E3W_G_R1_RUNNING_E3V_E3W_JOB_COUNT=0
E3W_G_R1_ELIGIBLE_E3V_E3W_JOB_COUNT=0
E3W_G_R1_DB_CLOSURE_OK
```

## PVESO / CT101 refined closure output

```text
PVESO_REFINED_CLOSURE=begin
OLLAMA_SERVICE_STATE=active
OLLAMA_LOCALHOST_11434_LISTENER_COUNT=1
OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0
PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_COUNT=1
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_LINES_BEGIN
 582357  339134       03:49 Sl   /usr/local/bin/ollama runner --model /var/lib/vz/ollama/models/blobs/sha256-eabc98a9bcbfce7fd70f3e07de599f8fda98120fefed5881934161ede8bd1a41 --port 38693
PVESO_IDLE_OR_LOADED_OLLAMA_RUNNER_LINES_END
CT101_STATUS=stopped
CT101_ONBOOT=0
E3W_G_R1_PVESO_RUNNER_CLASSIFICATION=idle_or_loaded_runner_present_no_active_client
E3W_G_R1_PVESO_REFINED_CLOSURE_OK
```

## Runner interpretation

The first E3W-G closure attempt found an Ollama runner process still loaded after the bounded 32B timeout. E3W-G-R1 refined this by separating active model clients from an idle or loaded Ollama runner.

No process was killed.

No service was restarted.

The closure condition is:

    PVESO_ACTIVE_MODEL_CLIENT_COUNT=0
    CT101_STATUS=stopped
    CT101_ONBOOT=0
    no E3V/E3W jobs running
    no eligible E3V/E3W jobs remaining

## Safety boundary

E3W-G-R1 did not:

- write the DB
- apply a schema migration
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

## Decision

The timeout-safe wrapper is now proven for the failure path.

The remaining blocker for a successful model-completion proof is not scheduler/claim safety. It is model latency/size: PVESO currently has only 19 GB / 32B-class local models, and the bounded 45-second call timed out.

Recommended next phase:

    E3X-A — select/install or prepare a smaller local proof model on PVESO, no scheduler activation

That next phase requires explicit approval if it pulls/downloads a model.

## Hard rules

Do not rerun E3V-Q.

Do not retry job 29.

Do not rerun job 30.

Use a fresh job id for any future runtime proof.
