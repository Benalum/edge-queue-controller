# Stage 16 E3Z-CY — Run CT101 Worker One-Shot Exact Job 45 Only

## Purpose

Record the approved bounded one-shot CT101 worker activation for exact job 45 only.

This stage temporarily ran the installed CT101 worker directly in one-shot mode with EDGE_WORKER_ENABLED=1 as a process environment override, while leaving the installed environment file disabled and the installed systemd service inactive and disabled.

## Approval

```text
APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY
```

## Mutation scope

Allowed:

- one CT101 worker process
- one exact job claim for job 45 only
- one model call to qwen2.5:0.5b
- one exact completion for job 45 only
- read-only preflight and postflight guards
- repo documentation/smoke commit/tag

Not allowed:

- no persistent worker service start
- no worker enable
- no worker unmask
- no scheduler/timer activation
- no additional job insert
- no Docker/model data mutation
- no model concurrency

## Completed job

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
```

## Verified CT203 state after completion

Expected postflight:

- DB integrity ok
- jobs_total: 44
- job_results_total: 25
- jobs_status_running: 0
- job 45 completed attempts=1 result_rows=1
- jobs 37 through 44 unchanged

## Verified CT101 runtime posture after completion

Expected postflight:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains unchanged
- only ollama container running
- no scheduler/timer activation

## Next step

Next step is CZ: read-only post-activation guard and documentation.

No additional model calls should occur in CZ.

## Non-goals

Do not rerun jobs 37 through 45.

Do not insert additional jobs.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency in the first worker activation.
