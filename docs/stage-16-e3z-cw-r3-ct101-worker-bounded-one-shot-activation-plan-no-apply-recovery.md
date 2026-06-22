# Stage 16 E3Z-CW-R3 — CT101 Worker Bounded One-Shot Activation Plan — No Apply Recovery

## Purpose

Recover the Stage 16 E3Z-CW no-apply activation plan after the first CW script left two untracked files and the R2 smoke used a backticked word that shell interpreted as command substitution.

This is a repository-only no-apply planning stage.

It does not mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, connect to live CT203, connect to live CT101, start or stop services, start or stop containers, delete Docker or model data, unmask worker services, enable timers, or activate scheduler paths.

## Prior checkpoint

Stage 16 E3Z-CV-R2 verified:

- repo: 99e2dd3
- tag: controller-stage-16-e3z-cv-r2-install-ct101-worker-disabled-postflight-recovery-2026-06-22
- CT203 DB integrity ok
- jobs_total: 43
- job_results_total: 24
- jobs_status_running: 0
- jobs 37 through 44 completed attempts=1 result_rows=1
- installed CT101 worker file exists
- installed CT101 model profile file exists
- installed CT101 disabled env file exists
- installed CT101 service file exists
- old ai-platform-laptop-queue-worker.service inactive and masked
- new edge-ct101-ollama-worker.service inactive and disabled
- only the ollama Docker container is running
- disabled worker refuses live --once execution with REFUSE_WORKER_DISABLED

## Activation principle

Activation must be separate from install.

The first activation should be a bounded one-shot proof, not a persistent worker rollout.

Recommended posture:

- create one fresh proof job only
- use one already-proven small model
- enable worker only for a bounded one-shot execution
- claim exactly one approved job
- complete exactly one approved job
- immediately restore disabled posture
- verify DB and runtime after
- do not enable scheduler
- do not enable timer
- do not leave worker running

## Recommended first worker activation model

Use qwen2.5:0.5b first.

Reasons:

- exact-marker proof success is already proven
- no qwen3 thinking-flag complexity
- low latency and low risk
- first worker proof should minimize model-specific complexity

Recommended fresh job:

```text
job_type: stage16_e3z_worker_one_shot_activation_proof
requested_model: qwen2.5:0.5b
expected_response: E3Z-WORKER-QWEN25-ONE-SHOT-OK
```

Do not reuse jobs 37 through 44.

## Future apply phases

### CX — insert one fresh worker activation proof job only

Allowed:

- insert one queued CT203 job
- requested_model qwen2.5:0.5b
- exact marker E3Z-WORKER-QWEN25-ONE-SHOT-OK
- no model calls
- no worker start
- no scheduler/timer activation

Explicit approval required.

Suggested phrase:

```text
APPROVE_STAGE_16_E3Z_CX_INSERT_ONE_FRESH_WORKER_ACTIVATION_PROOF_JOB_ONLY
```

### CY — bounded one-shot worker start for exact job only

Allowed:

- confirm CT203 DB and CT101 runtime readiness
- run the worker in bounded one-shot mode for the exact approved job only
- complete the exact job if output is exact
- restore EDGE_WORKER_ENABLED=0
- leave installed service inactive and disabled
- verify old worker remains inactive and masked
- verify only the ollama container is running
- verify no scheduler/timer activation

Explicit approval required.

Suggested phrase:

```text
APPROVE_STAGE_16_E3Z_CY_RUN_CT101_WORKER_ONE_SHOT_EXACT_JOB_ONLY
```

### CZ — read-only post-activation guard

Allowed:

- read-only CT203 DB verification
- read-only CT101 runtime verification
- verify worker service inactive and disabled
- verify old worker inactive and masked
- verify scheduler/timer inactive
- verify only the ollama container is running
- repo documentation/smoke commit

No model calls.

## One-shot execution design

Preferred first one-shot method:

```text
systemd-run --wait --collect --unit=edge-ct101-ollama-worker-oneshot-<job_id> \
  --property=Type=oneshot \
  --setenv=EDGE_WORKER_ENABLED=1 \
  --setenv=EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml \
  /usr/bin/python3 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py --once --job-id <job_id>
```

Rationale:

- avoids enabling the installed persistent service
- avoids unmasking old service
- runs one bounded invocation
- leaves installed service inactive and disabled
- gives explicit systemd logs for the single run

Alternative if systemd-run is not appropriate:

```text
EDGE_WORKER_ENABLED=1 \
EDGE_MODEL_PROFILE_FILE=/etc/edge-ct101-worker/model-profiles.yaml \
timeout 120s \
python3 /opt/edge-queue-controller/ops/workers/ct101_minimal_ollama_worker.py --once --job-id <job_id>
```

## Preflight guards for CY

CY must refuse unless:

- repo HEAD/origin matches the expected checkpoint
- CT203 DB integrity is ok
- jobs 37 through 44 remain completed
- no running jobs exist before activation
- the exact fresh activation job exists and is queued attempts=0 result_rows=0
- requested_model is qwen2.5:0.5b
- expected marker is present
- old worker service is inactive and masked
- new worker service is inactive and disabled
- installed env contains EDGE_WORKER_ENABLED=0 before activation
- installed profile validates
- worker self-test passes
- Docker/containerd are active
- only the ollama container is running
- qwen2.5:0.5b is present

## Postflight guards for CY

CY must verify:

- exact fresh job completed attempts=1 result_rows=1
- response text equals E3Z-WORKER-QWEN25-ONE-SHOT-OK
- jobs 37 through 44 unchanged
- jobs_status_running is 0
- installed env restored to EDGE_WORKER_ENABLED=0
- old worker service remains inactive and masked
- new worker service remains inactive and disabled
- no scheduler/timer activation
- only the ollama container is running
- no Docker/model data deletion
- no broad compose stack activation

## Failure handling

If model output is non-exact:

- do not complete the job
- do not claim another job
- restore EDGE_WORKER_ENABLED=0
- stop any transient one-shot unit if present
- run read-only validator
- require a separate continuation or fail-job approval

If worker exits after claim but before completion:

- do not rerun blindly
- identify the exact running job
- inspect logs
- run read-only DB validator
- complete only if exact output was safely captured
- otherwise require a separate fail-job path

## Scheduler and timer posture

Scheduler/timer must remain inactive through CX, CY, and CZ.

The one-shot worker proof must not enable:

- scheduler lane dispatch
- persistent lane workers
- systemd timer activation
- recurring worker loops

## Non-goals

Do not rerun jobs 37 through 44.

Do not insert more than one activation proof job in CX.

Do not call models in CX.

Do not call models in CZ.

Do not start a persistent CT101 worker loop.

Do not enable the CT101 worker service.

Do not unmask the old CT101 worker service.

Do not activate scheduler or timer.

Do not start broader /opt/ai-platform compose stacks.

Do not expose model endpoints directly to public users.

Do not change CT203 claim endpoint behavior.

Do not enable model concurrency in the first worker activation.
