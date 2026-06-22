# Stage 16 E3Z-DE — Service-Managed Postflight Read-Only Guard

## Purpose

Record the read-only postflight guard after the first service-managed CT101 worker one-shot proof.

This stage did not mutate CT203 DB state, call models, start workers, enable services, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Prior service-managed activation

Stage 16 E3Z-DD proved service-managed CT101 worker one-shot activation through a transient systemd unit:

```text
unit: edge-ct101-ollama-worker-oneshot-job46.service
method: systemd-run --wait --collect
job_id: 46
job_type: stage16_e3z_service_managed_worker_one_shot_proof
requested_model: qwen2.5:0.5b
response_text: E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
```

The earlier direct installed-worker one-shot proof remains:

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
```

## Verified CT203 DB state

Expected read-only guard state:

```text
db_integrity: ok
jobs_total: 45
job_results_total: 26
jobs_status_running: 0
jobs_max_id: 46
```

Jobs 37 through 46 remain completed, each with attempts=1 and result_rows=1.

Job 46 remains:

```text
status: completed
attempts: 1
requested_model: qwen2.5:0.5b
job_type: stage16_e3z_service_managed_worker_one_shot_proof
response_text: E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
error: None
```

## Verified CT101 runtime state

Expected read-only guard state:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
- transient edge-ct101-ollama-worker-oneshot-job46.service is not left active
- worker self-test passes against installed profile
- disabled worker refuses live --once execution with REFUSE_WORKER_DISABLED
- Docker, docker.socket, and containerd active
- only ollama container running
- qwen2.5:0.5b and qwen3:0.6b present

## Scheduler/timer state

The read-only guard checked edge/queue/worker/scheduler related units and active timers and refused if a clear active scheduler/timer/worker unit was found outside the controller service.

The intended final posture remains:

- no scheduler activation
- no timer activation
- no persistent worker activation
- no recurring worker loop

## Milestone result

Stage 16 E3Z has now proven:

1. CT101 can host installed worker artifacts while disabled.
2. CT203 can queue direct and service-managed worker activation proof jobs.
3. The installed CT101 worker can run as a direct bounded one-shot process.
4. The installed CT101 worker can run as a service-managed transient systemd one-shot process.
5. The worker can claim exactly one approved CT203 job.
6. The worker can call the local Ollama runtime through the contained ollama container.
7. The worker can complete the job with exact-marker output.
8. The system can return to a disabled, non-persistent posture.

## Recommended next step

Move from one-off proof to a controlled planning checkpoint for limited production-style worker operation.

Recommended next phase:

```text
Stage 16 E3Z-EA — limited persistent worker service design — no apply
```

This should still be no-apply planning only. Do not enable a persistent worker loop yet.

## Non-goals

Do not rerun jobs 37 through 46.

Do not insert additional jobs in DE.

Do not call models in DE.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency yet.
