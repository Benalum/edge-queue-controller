# Stage 16 E3Z-DD — Run Service-Managed CT101 Worker One-Shot Exact Job 46 Only

## Purpose

Record the approved service-managed bounded one-shot CT101 worker activation for exact job 46 only.

This stage used a transient systemd unit through systemd-run --wait --collect to run the installed CT101 worker as a bounded one-shot process. It did not start, enable, or unmask the installed persistent worker service.

## Approval

```text
APPROVE_STAGE_16_E3Z_DD_RUN_SERVICE_MANAGED_CT101_WORKER_ONE_SHOT_EXACT_JOB_46_ONLY
```

## Mutation scope

Allowed:

- one transient systemd-managed CT101 worker process
- one exact job claim for job 46 only
- one model call to qwen2.5:0.5b
- one exact completion for job 46 only
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
job_id: 46
job_type: stage16_e3z_service_managed_worker_one_shot_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
response_text: E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
```

## Verified CT203 state after completion

Expected postflight:

- DB integrity ok
- jobs_total: 45
- job_results_total: 26
- jobs_status_running: 0
- max job id: 46
- job 46 completed attempts=1 result_rows=1
- jobs 37 through 45 unchanged

## Verified CT101 runtime posture after completion

Expected postflight:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains unchanged
- transient systemd unit not left active
- only ollama container running
- no scheduler/timer activation

## Service-managed execution shape

The bounded proof used a transient unit equivalent to:

```text
systemd-run --wait --collect --unit=edge-ct101-ollama-worker-oneshot-job46 --property=Type=oneshot --property=TimeoutStartSec=180 ...
```

The transient process loaded /etc/edge-ct101-worker/ct101-worker.env and overrode EDGE_WORKER_ENABLED=1 only for that transient process.

The installed env remained disabled:

```text
EDGE_WORKER_ENABLED=0
```

## Next step

Next step is DE: read-only service-managed postflight guard and documentation.

No additional model calls should occur in DE.

## Non-goals

Do not rerun jobs 37 through 46.

Do not insert additional jobs.

Do not call models in DE.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency yet.
