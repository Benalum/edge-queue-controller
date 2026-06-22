# Stage 16 E3Z-EI — Controlled Expansion Decision / Design — No Apply

## Purpose

Choose the next controlled expansion after the first successful bounded limited-persistent CT101 worker proof.

This is a repository-only no-apply decision/design checkpoint. It does not access live hosts, mutate CT203 DB state, insert jobs, claim jobs, complete jobs, fail jobs, call models, start workers, enable workers, unmask services, activate scheduler/timer paths, or mutate Docker/Ollama model data.

## Current proven state

Stage 16 E3Z now has three progressively stronger worker proofs:

```text
job 45 direct installed-worker one-shot:
E3Z-WORKER-QWEN25-ONE-SHOT-OK

job 46 service-managed transient systemd one-shot:
E3Z-SERVICE-WORKER-QWEN25-ONE-SHOT-OK

job 47 bounded limited-persistent transient service proof:
E3Z-PERSISTENT-WORKER-QWEN25-ONE-JOB-OK
```

Post-EH idle guard proved:

```text
db_integrity: ok
jobs_total: 46
job_results_total: 27
jobs_status_running: 0
jobs_max_id: 47
old worker: inactive/masked
installed worker: inactive/disabled
active transients: none
edge timers: none
installed env: EDGE_WORKER_ENABLED=0
container set: ollama only
quiet-window DB signature: stable
```

## Important note on EH output

EH sample A printed `dev-mqueue.mount` under the broad `edge_scheduler_units` diagnostic because the grep expression included the substring `queue`, and `mqueue` matched. This is diagnostic noise, not an edge queue scheduler activation. The actual timer guard was clean:

```text
edge_timers=<none>
```

## Decision goal

The next step should expand capability without jumping directly to scheduler/timer activation or open-ended persistent service behavior.

The next expansion should prove repeatability and guard behavior under the same one-job-only controls before any broader worker window.

## Recommended expansion path

### EJ — repeat limited persistent one-job proof with a fresh qwen25 job

This is the recommended next live proof.

Purpose:

- prove the limited persistent proof path is repeatable
- use a new job id, expected to be 48
- keep qwen25 model path
- keep exactly one allowed job id
- keep transient service run
- keep installed persistent service disabled
- keep scheduler/timer inactive
- keep model concurrency disabled

Expected new marker:

```text
E3Z-PERSISTENT-WORKER-QWEN25-REPEAT-OK
```

Recommended job type:

```text
stage16_e3z_limited_persistent_worker_repeat_proof
```

Recommended phase sequence:

1. **EJ-A** repo/live profile update no worker start, if needed.
2. **EJ-B** insert exactly one fresh repeat proof job only.
3. **EJ-C** run limited persistent transient worker service exact job 48 only.
4. **EJ-D** read-only postflight idle guard.

If the existing job type `stage16_e3z_limited_persistent_worker_one_job_proof` is reused, EJ-A can be skipped and EJ-B can insert a fresh job using the already-allowed profile. For cleaner auditability, use a new repeat-specific job type and do EJ-A.

## Alternative expansion options

### Option A — repeat same qwen25 job type

Lower friction, fewer changes.

Pros:

- no profile update required
- uses proven job type and worker path
- fastest repeatability proof

Cons:

- less explicit audit separation between first proof and repeat proof

### Option B — add repeat-specific qwen25 job type

Recommended.

Pros:

- clear audit trail
- proves profile allowlist updates remain safe
- separates first proof from repeat proof
- keeps qwen3 excluded

Cons:

- one extra profile-update phase

### Option C — qwen3 limited-persistent proof

Not recommended yet.

Pros:

- proves second model/profile under same worker guards

Cons:

- qwen3 thinking flags and output behavior have more complexity
- better after one qwen25 repeat proof

### Option D — small exact allowlist with two jobs

Not recommended yet.

Pros:

- moves toward bounded queue window

Cons:

- increases risk from one-job guarantee to multi-job processing
- should wait until repeat one-job proof succeeds

### Option E — scheduler/timer activation

Not recommended yet.

Pros:

- gets closer to autonomous processing

Cons:

- broader activation surface
- should wait until repeat limited-persistent proof and a fresh postflight guard pass

## Hard gates for next live phase

Any next live proof must preserve:

```text
EDGE_WORKER_ENABLED=0 in installed env
edge-ct101-ollama-worker.service inactive/disabled after proof
ai-platform-laptop-queue-worker.service inactive/masked
no active transient worker units after proof
no scheduler/timer activation
EDGE_ALLOW_MODEL_CONCURRENCY=0
EDGE_ALLOWED_JOB_IDS=<exact single fresh job id>
EDGE_EXIT_AFTER_ONE_SUCCESS=1
EDGE_MAX_RUNTIME_SECONDS=180
only ollama container running
no mutation of jobs 37 through 47
```

## Recommended next phase

Proceed with **EJ-A**: add repeat-specific qwen25 limited persistent job type to the profile, no worker start.

Approval required:

```text
APPROVE_STAGE_16_E3Z_EJ_A_ADD_REPEAT_LIMITED_PERSISTENT_JOB_TYPE_TO_QWEN25_PROFILE_NO_WORKER_START
```

## Future target after repeat proof

After EJ-A through EJ-D succeed, proceed to **EK** no-apply design for a very small bounded worker window.

EK should design:

```text
EDGE_ALLOWED_JOB_IDS=<job_a,job_b>
EDGE_MAX_COMPLETIONS=2
EDGE_EXIT_AFTER_N_SUCCESS=2
EDGE_MAX_RUNTIME_SECONDS=300
no scheduler/timer yet
no installed service enablement
```

Only after EK and another proof should scheduler/timer activation be reconsidered.
