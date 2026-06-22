# Stage 16 E3Z-DA — Service-Managed CT101 Worker One-Shot Plan — No Apply

## Purpose

Plan the next step after the direct bounded CT101 worker one-shot proof.

This is a repository-only no-apply planning stage. It does not access live hosts, mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Current proven milestone

Stage 16 E3Z-CY and E3Z-CZ proved:

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
```

Post-activation guard verified:

```text
jobs_total: 44
job_results_total: 25
jobs_status_running: 0
jobs_max_id: 45
```

Runtime posture after proof:

```text
old worker: inactive and masked
new worker: inactive and disabled
installed env: EDGE_WORKER_ENABLED=0
running containers: ollama only
scheduler/timer: not activated
```

## Why DA is no-apply

The direct one-shot proof used a direct process invocation with an environment override.

The next step should plan a service-managed one-shot without actually starting the service yet. A service-managed proof will validate that systemd can run the installed worker in a bounded oneshot style while still avoiding persistent worker rollout.

## Target outcome for future DB phase

A future DB-insert phase should create one fresh service-managed worker proof job.

Recommended job:

```text
job_type: stage16_e3z_service_managed_worker_one_shot_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
```

Do not reuse jobs 37 through 45.

## Required profile repair before service-managed proof

Before the service-managed job is run, the qwen25 profile must allow the service-managed job type:

```text
stage16_e3z_service_managed_worker_one_shot_proof
```

That repair should be a separate phase or included in the same insert-prep phase only if it is still no-start and no-model-call.

## Recommended phase split

### DB — add service-managed job type to qwen25 profile, no start

Allowed:

- update repo profile
- update installed CT101 profile
- run self-test only
- verify current job state read-only
- no worker start
- no model call

Approval required because it mutates installed CT101 profile.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_DB_ADD_SERVICE_MANAGED_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

### DC — insert one fresh service-managed worker proof job only

Allowed:

- insert one queued CT203 job
- requested_model qwen2.5:0.5b
- expected marker E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
- no worker start
- no model call
- no scheduler/timer activation

Approval required because it mutates CT203 DB.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_DC_INSERT_ONE_FRESH_SERVICE_MANAGED_WORKER_PROOF_JOB_ONLY
```

### DD — service-managed bounded one-shot execution for exact fresh job only

Allowed:

- use systemd-run or a transient unit to run the installed worker as a bounded one-shot
- set EDGE_WORKER_ENABLED=1 only in the transient process environment
- leave installed env file with EDGE_WORKER_ENABLED=0
- claim exactly the approved fresh job
- call qwen2.5:0.5b once
- complete only if exact marker
- verify worker is not left running
- verify installed service remains inactive and disabled

Approval required because it starts a bounded worker process and calls the model.

Suggested approval phrase:

```text
APPROVE_STAGE_16_E3Z_DD_RUN_SERVICE_MANAGED_CT101_WORKER_ONE_SHOT_EXACT_JOB_ONLY
```

### DE — read-only service-managed postflight guard

Allowed:

- read-only CT203 DB validation
- read-only CT101 runtime validation
- repo documentation/smoke commit
- no model calls
- no worker starts

No activation approval required if strictly read-only/repo-only.

## Preferred service-managed execution design

Preferred method for DD:

```text
systemd-run --wait --collect \
  --unit=edge-ct101-ollama-worker-oneshot-<job_id> \
  --property=Type=oneshot \
  --property=TimeoutStartSec=180 \
  --setenv=EDGE_WORKER_ENABLED=1 \
  --setenv=EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml \
  --setenv=EDGE_MAX_JOBS_PER_LOOP=1 \
  --setenv=EDGE_CLAIM_POLICY=one_at_a_time \
  --setenv=EDGE_ALLOW_MODEL_CONCURRENCY=0 \
  /usr/bin/python3 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py --once --job-id <job_id>
```

This avoids enabling the installed persistent service while proving that systemd can manage a bounded worker execution.

## Required DD preflight guards

DD must refuse unless:

- repo HEAD/origin matches expected checkpoint
- CT203 DB integrity is ok
- jobs 37 through 45 remain completed attempts=1 result_rows=1
- no running jobs exist
- the exact fresh service-managed proof job is queued attempts=0 result_rows=0
- requested_model is qwen2.5:0.5b
- expected marker is present in prompt or metadata
- old ai-platform-laptop-queue-worker.service is inactive and masked
- new edge-ct101-ollama-worker.service is inactive and disabled
- installed env contains EDGE_WORKER_ENABLED=0
- installed qwen25 profile allows service-managed job type
- worker self-test passes
- Docker/containerd are active
- only ollama container is running
- qwen2.5:0.5b is present

## Required DD postflight guards

DD must verify:

- exact fresh job completed attempts=1 result_rows=1
- response text equals E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK
- jobs 37 through 45 unchanged
- jobs_status_running is 0
- transient systemd unit is gone or inactive
- installed worker service remains inactive and disabled
- old worker service remains inactive and masked
- installed env still contains EDGE_WORKER_ENABLED=0
- only ollama container is running
- no scheduler/timer activation
- no Docker/model data deletion

## Failure handling

If the model output is non-exact:

- do not complete the job as successful
- do not claim another job
- preserve logs
- verify worker stopped
- verify installed env remains disabled
- run read-only DB and runtime validators
- require a separate fail-job or recovery approval

If the transient systemd unit fails:

- do not rerun blindly
- inspect the unit logs
- verify whether the job was claimed
- if claimed but incomplete, follow a separate recovery/fail path
- do not start persistent service

## What this does not do

This plan does not enable persistent workers.

This plan does not enable scheduler.

This plan does not enable timer.

This plan does not create a recurring worker loop.

This plan does not enable model concurrency.

This plan does not expose model endpoints to public users.

This plan does not change CT203 claim endpoint behavior.

## Recommended next step

Proceed with DB: add the service-managed proof job type to the qwen25 profile, no worker start.

Use explicit approval:

```text
APPROVE_STAGE_16_E3Z_DB_ADD_SERVICE_MANAGED_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```
