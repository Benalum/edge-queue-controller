# Stage 16 E3Z-CZ — Read-Only Post-Activation Guard

## Purpose

Record the read-only post-activation guard after the first installed CT101 worker one-shot proof.

This stage did not mutate CT203 DB state, call models, start workers, enable services, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Prior activation

Stage 16 E3Z-CY proved the first installed CT101 worker one-shot activation:

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
jobs_total: 44
job_results_total: 25
jobs_status_running: 0
jobs_max_id: 45
```

Jobs 37 through 45 remain completed, each with attempts=1 and result_rows=1.

Job 45 remains:

```text
status: completed
attempts: 1
requested_model: qwen2.5:0.5b
job_type: stage16_e3z_worker_one_shot_activation_proof
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
error: None
```

## Verified CT101 runtime state

Expected read-only guard state:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- installed EDGE_WORKER_ENABLED=0 remains set
- EDGE_CLAIM_POLICY=one_at_a_time remains set
- EDGE_ALLOW_MODEL_CONCURRENCY=0 remains set
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
2. CT203 can queue one worker activation proof job.
3. The installed CT101 worker can run as a bounded one-shot process.
4. The worker can claim exactly one approved CT203 job.
5. The worker can call the local Ollama runtime through the contained ollama container.
6. The worker can complete the job with exact-marker output.
7. The system can return to a disabled, non-persistent posture.

## Recommended next step

Move from one-shot proof to a controlled no-apply plan for a second worker proof or a service-managed one-shot.

Recommended next phase:

```text
Stage 16 E3Z-DA — service-managed CT101 worker one-shot plan — no apply
```

No persistent worker loop should be enabled yet.

## Non-goals

Do not rerun jobs 37 through 45.

Do not insert additional jobs in CZ.

Do not call models in CZ.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency yet.
