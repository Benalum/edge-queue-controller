# Stage 16 E3Z-CX — Insert One Fresh Worker Activation Proof Job Only

## Purpose

Record the approved CT203 DB insert of one fresh queued worker activation proof job.

This stage inserted one queued job only and did not start the worker, call models, claim jobs, complete jobs, fail jobs, enable scheduler, enable timer, or mutate Docker/Ollama model data.

## Approval

```text
APPROVE_STAGE_16_E3Z_CX_INSERT_ONE_FRESH_WORKER_ACTIVATION_PROOF_JOB_ONLY
```

## Mutation scope

Allowed:

- insert exactly one queued CT203 job
- repo documentation/smoke commit/tag
- read-only CT101 runtime guard after insert

Not allowed:

- no model call
- no worker start
- no worker enable
- no worker unmask
- no scheduler/timer activation
- no job claim
- no job complete
- no job fail
- no Docker/model data mutation

## Inserted job

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: queued
attempts: 0
result_rows: 0
```

## Verified CT203 state after insert

Expected post-insert state:

- DB integrity: ok
- jobs_total: 44
- job_results_total: 24
- jobs_status_running: 0
- max job id: 45
- job 45 queued attempts=0 result_rows=0
- jobs 37 through 44 remain unchanged completed proof jobs

## Verified CT101 runtime guard after insert

Expected runtime posture:

- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- EDGE_WORKER_ENABLED=0 remains installed
- Docker/containerd active
- only ollama container running

## Next step

Next step is CY: bounded one-shot worker execution for exact job 45 only.

CY is a real worker/model/claim/complete activation and requires separate explicit approval.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY
```

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert additional jobs.

Do not call models in CX.

Do not start CT101 persistent worker service.

Do not unmask CT101 persistent worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency in the first worker activation.
