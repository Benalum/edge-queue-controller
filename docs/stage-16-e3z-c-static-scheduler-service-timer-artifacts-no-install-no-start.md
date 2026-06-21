# Stage 16 E3Z-C — Static Scheduler Service/Timer Artifacts, No Install/No Start

## Phase status

MUTATION_SCOPE: repo static artifacts, docs, smoke, commit, tag, and push only.

This phase creates repo-static templates and a fail-closed scheduler tick harness.

E3Z-C does not:

- write the DB
- insert a job
- claim a job
- execute the scheduler
- execute the wrapper
- call a model endpoint
- pull a model
- install a service
- enable/start/restart/reload a service
- install a timer
- enable/start/restart/reload a timer
- activate the scheduler
- activate persistent workers
- start CT101
- mutate CTs, VMs, Cloudflare, or private storage

## Checkpoint entering E3Z-C

- Previous HEAD/origin/main: `4ca970e`
- Previous tag: `controller-stage-16-e3z-b-persistent-scheduler-service-timer-design-no-activation-2026-06-21`
- DB authority: CT203
- DB path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- Closed proof jobs: job 29, job 30, job 31, job 32
- Persistent scheduler: blocked
- Persistent workers: disabled
- CT101: stopped and onboot=0

## Static artifacts

Static fail-closed harness:

```text
ops/scheduler/stage-16-e3z-scheduler-tick.sh
```

Static service template:

```text
ops/systemd/edge-queue-scheduler-one-shot.service
```

Static timer template:

```text
ops/systemd/edge-queue-scheduler-one-shot.timer
```

Focused smoke:

```text
ops/smoke/check-stage-16-e3z-c-static-scheduler-service-timer-artifacts-no-install-no-start.sh
```

## Harness contract

The harness is fail-closed.

It refuses unless a future explicit activation phase supplies all required variables:

```text
APC_STAGE16_E3Z_SCHEDULER_TIMER_APPROVAL=APPROVE_STAGE_16_E3Z_TIMER_ONE_JOB_PER_TICK_FRESH_PROOF_ONLY
EDGE_QUEUE_CONTROLLER_DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3
EDGE_SCHEDULER_MODE=one-shot-timer
EDGE_SCHEDULER_ONE_JOB_PER_TICK=1
EDGE_SCHEDULER_MAX_JOBS_PER_TICK=1
EDGE_SCHEDULER_MAX_RUNTIME_SECONDS=120
EDGE_SCHEDULER_EXACT_JOB_ID=<fresh_job_id_only>
EDGE_SCHEDULER_ALLOWED_JOB_TYPE=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
EDGE_SCHEDULER_ALLOWED_MODEL=qwen2.5:0.5b
EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0
EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=1
```

During E3Z-C, delegation remains disabled.

## Fresh proof job rule

A future activation proof must use a fresh job.

Forbidden historical jobs:

- job 29
- job 30
- job 31
- job 32

Recommended future proof job type:

```text
stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
```

Recommended future proof model:

```text
qwen2.5:0.5b
```

The fresh proof job insert requires a separate explicit DB-write approval phase.

## One-job-per-tick policy

The intended later flow is:

```text
timer tick
-> oneshot service
-> E3Z harness
-> proven E3Y one-shot scheduler wrapper
-> proven E3W timeout-safe wrapper
-> one fresh queued proof job
-> one bounded PVESO Ollama call
-> one completion transaction
-> service exits
```

No broad queue drain is allowed.

## Activation remains blocked

E3Z-C does not activate the scheduler.

E3Z-C does not enable/start the timer.

E3Z-C does not install the service.

E3Z-C does not enable/start persistent workers.

E3Z-C does not start CT101.

## Next recommended phase

E3Z-D should be an activation and rollback plan only, with no live mutation.

No runtime activation should occur until a later explicit approval phase.
