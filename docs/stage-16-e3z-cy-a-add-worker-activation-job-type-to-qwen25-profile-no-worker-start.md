# Stage 16 E3Z-CY-A — Add Worker Activation Job Type To Qwen25 Profile — No Worker Start

## Purpose

Record the approved profile repair required before the bounded one-shot CT101 worker activation.

This stage added the job type `stage16_e3z_worker_one_shot_activation_proof` to the qwen25 router-small model profile in both the repository profile artifact and the installed CT101 profile.

## Approval

```text
APPROVE_STAGE_16_E3Z_CY_A_ADD_WORKER_ACTIVATION_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Why this was needed

Job 45 was inserted by E3Z-CX as the fresh worker activation proof job:

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: queued
attempts: 0
result_rows: 0
```

Before this profile update, the installed qwen25 profile allowed earlier concurrency proof job types but did not allow this new activation proof job type. Running the worker without this repair could have claimed job 45 and then rejected it as not eligible.

## Mutation scope

Allowed:

- update repository model profile artifact
- update installed CT101 model profile at /etc/edge-ct101-worker/model-profiles.yaml
- run worker self-test only
- read-only CT203 job 45 guard before and after
- read-only CT101 service/container posture guard before and after
- repo documentation/smoke commit/tag

Not allowed:

- no worker start
- no worker enable
- no worker unmask
- no model call
- no job claim
- no job complete
- no job fail
- no scheduler/timer activation
- no Docker/model data mutation

## Profile change

Added this allowed job type to qwen25_router_small:

```text
stage16_e3z_worker_one_shot_activation_proof
```

qwen3_router_small was not changed for this job type.

## Verified post-update posture

Expected post-update posture:

- CT203 DB integrity ok
- job 45 remains queued attempts=0 result_rows=0
- jobs_total remains 44
- job_results_total remains 24
- jobs_status_running remains 0
- installed worker self-test passes against installed profile
- old ai-platform-laptop-queue-worker.service remains inactive and masked
- new edge-ct101-ollama-worker.service remains inactive and disabled
- EDGE_WORKER_ENABLED=0 remains installed
- only ollama container is running

## Next step

Next step is CY: bounded one-shot CT101 worker execution for exact job 45 only.

CY is a real worker/model/claim/complete activation and requires separate explicit approval.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_45_ONLY
```

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert additional jobs.

Do not call models in CY-A.

Do not claim job 45 in CY-A.

Do not start CT101 worker service in CY-A.

Do not unmask CT101 worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency in the first worker activation.
