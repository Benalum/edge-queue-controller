# Stage 16 E3Z-EG — Run Limited Persistent Worker Service Exact Job 47 Only

## Purpose

Run the installed CT101 worker through a bounded transient systemd service in limited persistent one-job proof mode, claiming and completing exactly job 47.

This stage performed one worker activation, one exact job claim, one qwen2.5 model call, and one completion for job 47 only.

## Approval

```text
APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_47_ONLY
```

## Activation scope

```text
unit: edge-ct101-ollama-worker-limited-job47.service
worker_mode: --loop
EDGE_PROOF_MODE: limited_persistent_one_job
EDGE_ALLOWED_JOB_IDS: 47
EDGE_EXIT_AFTER_ONE_SUCCESS: 1
EDGE_MAX_RUNTIME_SECONDS: 180
EDGE_ALLOW_MODEL_CONCURRENCY: 0
requested_model: qwen2.5:0.5b
job_type: stage16_e3z_limited_persistent_worker_one_job_proof
expected_response: E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## Proof result

```text
E3Z_WORKER_LIMITED_PERSISTENT_ONE_JOB_SUCCESS=1
job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## CT203 DB result

Expected CT203 state after EG:

```text
db_integrity: ok
jobs_total: 46
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 47
job 45 completed attempts=1 result_rows=1 response=E3Z-WORKER-QWEN25-ONE-SHOT-OK
job 46 completed attempts=1 result_rows=1 response=E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
job 47 completed attempts=1 result_rows=1 response=E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

## CT101 runtime posture after EG

Expected CT101 state after EG:

- old ai-platform-laptop-queue-worker.service inactive and masked
- installed edge-ct101-ollama-worker.service inactive and disabled
- transient edge-ct101-ollama-worker-limited-job47.service exited successfully and did not remain active
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- only ollama container running
- no active transient worker units remain

## Non-goals

Do not enable or unmask CT101 worker services in EG.

Do not start the installed persistent service directly in EG.

Do not activate scheduler or timer in EG.

Do not enable model concurrency in EG.

Do not insert jobs in EG.

Do not rerun jobs 37 through 46.

Do not claim any job other than 47.

## Recommended next step

Proceed with EH: read-only postflight/idle guard after limited persistent worker proof.

EH should verify no worker remains active, no scheduler/timer activation occurred, CT203 DB is stable, and job 47 is completed exactly once.
