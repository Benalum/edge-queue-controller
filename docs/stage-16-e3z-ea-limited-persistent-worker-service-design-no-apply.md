# Stage 16 E3Z-EA — Limited Persistent Worker Service Design — No Apply

## Purpose

Design the next controlled step after proving both direct and service-managed one-shot CT101 worker execution.

This is a repository-only no-apply planning stage. It does not access live hosts, mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Current proven milestones

### Direct installed-worker one-shot proof

```text
job_id: 45
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
response_text: E3Z-WORKER-QWEN25-ONE-SHOT-OK
status: completed
attempts: 1
result_rows: 1
```

### Service-managed transient one-shot proof

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

### Latest guarded DB posture

```text
db_integrity: ok
jobs_total: 45
job_results_total: 26
jobs_status_running: 0
jobs_max_id: 46
jobs_37_through_46: completed, attempts=1, result_rows=1
```

### Latest guarded CT101 posture

```text
old worker: inactive and masked
new worker: inactive and disabled
installed env: EDGE_WORKER_ENABLED=0
claim policy: one_at_a_time
model concurrency: disabled
active transient units: none
running containers: ollama only
scheduler/timer: not activated
```

## Why EA is no-apply

Persistent worker service operation is the next risk tier. A persistent worker can repeatedly claim jobs, so it must be designed before activation.

The goal is not to enable a persistent worker yet. The goal is to design a limited, bounded persistent-worker proof that can later be approved separately.

## Proposed limited persistent worker proof

The first persistent-worker proof should not run indefinitely.

It should be designed as a bounded service start with strict external stop/guard behavior, such as:

```text
1. Insert exactly one fresh proof job.
2. Temporarily allow the installed service to run with EDGE_WORKER_ENABLED=1.
3. Start the service only after verifying one eligible queued job exists.
4. Stop the service immediately after job completion or timeout.
5. Disable/mask posture remains restored after the proof.
```

Preferred proof marker:

```text
E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

Recommended job type:

```text
stage16_e3z_limited_persistent_worker_one_job_proof
```

Recommended model:

```text
qwen2.5:0.5b
```

## Key design constraint

The first persistent worker proof must process exactly one eligible job.

It must not drain the queue, claim arbitrary queued work, or run as a recurring production worker.

## Preferred technical design

Use a wrapper or environment gate that supports one-job-only behavior.

Preferred future implementation options:

### Option A — Service environment override plus explicit job allowlist

Use a systemd drop-in or transient override with:

```text
EDGE_WORKER_ENABLED=1
EDGE_MAX_JOBS_PER_LOOP=1
EDGE_CLAIM_POLICY=one_at_a_time
EDGE_ALLOW_MODEL_CONCURRENCY=0
EDGE_ALLOWED_JOB_IDS=<fresh_job_id>
EDGE_EXIT_AFTER_ONE_SUCCESS=1
```

The worker must refuse if:

- no allowed job id is set
- more than one allowed job id is set
- the allowed job is not queued
- the allowed job type is not in qwen25 profile
- model concurrency is requested
- scheduler/timer is active
- an unexpected container is running

### Option B — New dedicated oneshot wrapper service

Create a dedicated service unit separate from the disabled persistent service:

```text
edge-ct101-ollama-worker-one-job.service
```

This would run the same worker binary with an explicit job id and exit after one completion. This is close to the DD transient proof but as an installed service artifact.

### Option C — Persistent service remains disabled; systemd-run remains the production-safe path for bounded jobs

Use transient systemd units for all bounded worker runs until the scheduler path is ready. This is safer but less representative of a persistent production worker.

## Recommended path

Use Option A only after adding explicit worker-side allowlist/exit guards to the worker script.

Do not start the current installed service as a persistent loop until the worker has these hard controls:

```text
EDGE_ALLOWED_JOB_IDS
EDGE_EXIT_AFTER_ONE_SUCCESS
EDGE_MAX_RUNTIME_SECONDS
EDGE_REFUSE_IF_SCHEDULER_ACTIVE
EDGE_REFUSE_IF_TIMER_ACTIVE
```

## Recommended phase split

### EB — Worker one-job allowlist/exit guard design — no apply

Repository-only design for worker-side controls.

No approval required if repo-only/no-apply.

### EC — Implement worker one-job allowlist/exit guard in repo only

Repository mutation only. No live install, no DB mutation, no model call.

No live activation approval required, but still safe to checkpoint.

### ED — Install updated worker files disabled only

Live CT101 file update, no service start, no model call.

Requires approval:

```text
APPROVE_STAGE_16_E3Z_ED_INSTALL_UPDATED_WORKER_GUARDS_DISABLED_ONLY_NO_START
```

### EE — Add limited persistent proof job type to qwen25 profile, no start

Live CT101 profile update, no service start, no model call.

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EE_ADD_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

### EF — Insert one fresh limited persistent proof job only

CT203 DB insert only.

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EF_INSERT_ONE_FRESH_LIMITED_PERSISTENT_WORKER_PROOF_JOB_ONLY
```

### EG — Limited persistent worker service one-job activation

Real worker/model/claim/complete activation.

Requires approval:

```text
APPROVE_STAGE_16_E3Z_EG_RUN_LIMITED_PERSISTENT_WORKER_SERVICE_EXACT_JOB_ONLY
```

### EH — Read-only limited persistent postflight guard

Read-only live validation and repo checkpoint.

No activation approval required if strictly read-only/repo-only.

## EG required preflight guards

EG must refuse unless all are true:

- repo HEAD/origin matches expected checkpoint
- CT203 DB integrity ok
- jobs 37 through 46 remain completed attempts=1 result_rows=1
- no running jobs exist
- exact fresh proof job is queued attempts=0 result_rows=0
- qwen25 profile allows limited persistent proof job type
- qwen3 profile does not allow it
- old ai-platform-laptop-queue-worker.service inactive and masked
- edge-ct101-ollama-worker.service inactive and disabled before activation
- installed env remains EDGE_WORKER_ENABLED=0 before activation
- no active transient worker units exist
- Docker/containerd active
- only ollama container running
- qwen2.5:0.5b present
- scheduler/timer units inactive
- one-job allowlist is exactly the fresh job id
- exit-after-one-success is enabled
- max runtime guard is enabled
- model concurrency remains disabled

## EG required activation behavior

EG should:

- temporarily permit worker execution for one exact job id
- start service only in bounded proof context
- call qwen2.5:0.5b once
- complete only if response exactly equals E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
- stop the worker immediately after success
- restore installed env/service posture to disabled/inactive
- leave scheduler/timer inactive
- not claim any other job

## EG required postflight guards

EG must verify:

- exact fresh job completed attempts=1 result_rows=1
- exact response is E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
- no other jobs changed
- jobs_status_running is 0
- installed persistent service inactive after proof
- old worker remains inactive/masked
- installed env restored to EDGE_WORKER_ENABLED=0
- no active transient worker units
- only ollama container running
- no scheduler/timer activation
- no Docker/model data deletion

## Failure handling

If a persistent-service proof starts but does not complete:

- stop the worker service immediately
- do not restart blindly
- do not claim another job
- inspect logs
- verify job state
- if the job is stuck running, require a separate recovery/fail approval
- preserve all logs
- restore disabled posture

If the model output is non-exact:

- do not mark successful
- stop worker
- require recovery/fail approval
- do not continue to scheduler activation

## Explicit non-goals

Do not enable a production persistent worker loop.

Do not enable scheduler.

Do not enable timer.

Do not enable model concurrency.

Do not allow more than one job id.

Do not allow queue drain behavior.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not unmask the old worker.

## Recommended next step

Proceed with EB: Worker one-job allowlist/exit guard design — no apply.

This is repository-only planning and should not require a live activation approval.
