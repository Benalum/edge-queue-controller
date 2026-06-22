# Stage 16 E3Z-DB-R2 — Add Service-Managed Job Type To Qwen25 Profile — Current-Head Guarded — No Worker Start

## Purpose

Record the approved profile update required before the service-managed CT101 worker one-shot proof.

The first DB script refused because the repository had advanced from the DA tag to a newer clean HEAD. DB-R2 accepted the current clean HEAD only after proving the DA tag was an ancestor and origin matched local HEAD.

## Approval

```text
APPROVE_STAGE_16_E3Z_DB_ADD_SERVICE_MANAGED_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Current-head guard

```text
base_tag: controller-stage-16-e3z-da-service-managed-ct101-worker-one-shot-plan-no-apply-2026-06-22
base_commit: 64e27ac
current_head_before_commit: 9bcaca8
```

## Why this was needed

The prior direct worker one-shot proof completed job 45:

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
```

The next service-managed proof will use a distinct job type:

```text
stage16_e3z_service_managed_worker_one_shot_proof
```

The qwen25 profile must allow that job type before the service-managed worker one-shot can safely claim it.

## Mutation scope

Allowed:

- update repository model profile artifact
- update installed CT101 model profile at /etc/edge-ct101-worker/model-profiles.yaml
- run worker self-test only
- read-only CT203 DB and job 45 guard before and after
- read-only CT101 service/container posture guard before and after
- repo documentation/smoke commit/tag

Not allowed:

- no worker start
- no worker enable
- no worker unmask
- no model call
- no job insert
- no job claim
- no job complete
- no job fail
- no scheduler/timer activation
- no Docker/model data mutation

## Profile change

Added this allowed job type to qwen25_router_small:

```text
stage16_e3z_service_managed_worker_one_shot_proof
```

The previous direct worker activation job type remains allowed:

```text
stage16_e3z_worker_one_shot_activation_proof
```

qwen3_router_small was not changed for the service-managed job type.

## Verified post-update posture

Expected post-update posture:

- CT203 DB integrity ok
- jobs_total remains 44
- job_results_total remains 25
- jobs_status_running remains 0
- jobs_max_id remains 45
- job 45 remains completed attempts=1 result_rows=1
- installed worker self-test passes against installed profile
- old ai-platform-laptop-queue-worker.service remains inactive and masked
- new edge-ct101-ollama-worker.service remains inactive and disabled
- EDGE_WORKER_ENABLED=0 remains installed
- only ollama container is running

## Next step

Next step is DC: insert one fresh service-managed worker proof job only.

DC is a real CT203 DB insert mutation and requires separate explicit approval.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_DC_INSERT_ONE_FRESH_SERVICE_MANAGED_WORKER_PROOF_JOB_ONLY
```

## Non-goals

Do not rerun jobs 37 through 45.

Do not insert additional jobs in DB-R2.

Do not call models in DB-R2.

Do not claim jobs in DB-R2.

Do not start CT101 worker service in DB-R2.

Do not unmask CT101 worker service.

Do not enable CT101 worker service.

Do not activate scheduler or timer.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency yet.
