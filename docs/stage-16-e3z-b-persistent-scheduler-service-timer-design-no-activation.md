# Stage 16 E3Z-B — Persistent Scheduler Service/Timer Design, No Activation

## Phase status

MUTATION_SCOPE: repo docs/smoke/commit/tag/push only.

This phase is design-only. It creates no systemd unit files, installs no service files, enables no timers, starts no services, writes no database rows, inserts no jobs, claims no jobs, executes no scheduler, executes no wrapper, calls no model endpoint, pulls no model, mutates no CT/VM/service/Cloudflare/private-storage state, and does not start CT101.

## Current checkpoint

- Repo checkpoint before this phase: `01f0abd`
- Previous tag: `controller-stage-16-e3z-a-persistent-scheduler-activation-readiness-plan-no-activation-2026-06-21`
- DB authority: CT203
- DB path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- Proven one-shot scheduler wrapper: `ops/scheduler/stage-16-e3y-one-shot-scheduler-dispatch.sh`
- Proven timeout-safe wrapper: `ops/scheduler/stage-16-e3w-timeout-safe-one-job-dispatch.sh`
- Closed jobs that must not be rerun: jobs 29, 30, 31, and 32
- Persistent scheduler: not activated
- Persistent workers: disabled
- CT101: stopped and onboot=0

## Design choice

Use a systemd timer that triggers a short-lived oneshot service, not a long-running daemon, for the first persistent scheduler proof.

Reason:

- each tick has a bounded execution window
- one scheduler attempt is visible in journal logs
- no while-true loop exists inside the service
- failure handling stays systemd-native
- rollback can stop/disable only the timer and service
- the first activation can be scheduler-only while persistent workers remain disabled

## Candidate future unit names

These are names for a later implementation phase only. They are not created or installed in E3Z-B.

- `edge-queue-scheduler-one-shot.service`
- `edge-queue-scheduler-one-shot.timer`

Future static repo templates may live under:

- `ops/systemd/edge-queue-scheduler-one-shot.service`
- `ops/systemd/edge-queue-scheduler-one-shot.timer`

Future installed host paths may be:

- `/etc/systemd/system/edge-queue-scheduler-one-shot.service`
- `/etc/systemd/system/edge-queue-scheduler-one-shot.timer`

No service/timer install occurs in this phase.

## Candidate scheduler harness

A future static implementation may add a bounded harness such as:

- `ops/scheduler/stage-16-e3z-scheduler-tick.sh`

The harness should call the existing proven one-shot scheduler wrapper, not bypass it.

For the first activation proof, the harness should require:

- exact approval token
- exact fresh job id
- exact fresh job type
- exact proof model
- one job per tick
- no historical proof job ids

The harness must not implement a broad queue-draining loop.

## Environment variable contract

Future implementation should use explicit environment variables with safe defaults.

Required future variables:

- `EDGE_QUEUE_CONTROLLER_DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3`
- `EDGE_SCHEDULER_MODE=one-shot-timer`
- `EDGE_SCHEDULER_ONE_JOB_PER_TICK=1`
- `EDGE_SCHEDULER_MAX_JOBS_PER_TICK=1`
- `EDGE_SCHEDULER_MAX_RUNTIME_SECONDS=120`
- `EDGE_SCHEDULER_EXACT_JOB_ID=<fresh_job_id_only>`
- `EDGE_SCHEDULER_ALLOWED_JOB_TYPE=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke`
- `EDGE_SCHEDULER_ALLOWED_MODEL=qwen2.5:0.5b`
- `EDGE_SCHEDULER_REQUIRE_CLEAN_REPO=1`
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0`
- `APC_STAGE16_E3Z_SCHEDULER_TIMER_APPROVAL=<future_explicit_approval_token>`

The service must refuse to run if `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is truthy.

## One-job-per-tick policy

The first persistent scheduler proof must process at most one job per timer tick.

Required behavior:

1. Timer triggers oneshot service.
2. Service starts bounded scheduler harness.
3. Harness validates activation gates.
4. Harness delegates exactly one fresh queued job to the proven one-shot scheduler wrapper.
5. Wrapper delegates to the timeout-safe wrapper.
6. Timeout-safe wrapper performs the bounded PVESO Ollama call.
7. Completion writes exactly one `job_results` row.
8. Service exits.
9. Timer waits for the next configured tick.

No loop may continue selecting additional jobs in the same service invocation.

## Fresh proof job strategy

Future activation proof must use a fresh job.

Forbidden historical jobs:

- job 29
- job 30
- job 31
- job 32

Recommended fresh proof attributes:

- model: `qwen2.5:0.5b`
- job type: `stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke`
- expected starting state: queued
- expected starting attempts: 0
- expected starting result rows: 0
- expected completion: completed
- expected final result rows: 1
- expected final attempts: 1

The fresh proof job insertion itself must be a separate explicit DB-write approval phase.

## Activation refusal gates

A future service/timer activation must refuse to run unless all gates pass.

Required gates:

- exact explicit activation approval token is present
- repo HEAD and origin/main match the expected checkpoint for that phase
- working tree is clean
- DB path is exactly `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- DB integrity is `ok`
- no duplicate `job_results` rows exist
- exact fresh job id is provided
- exact job id is not 29, 30, 31, or 32
- exact job is queued
- exact job has attempts 0
- exact job has result rows 0
- exact job type is `stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke`
- exact model is `qwen2.5:0.5b`
- no queued/running stale Stage 16 proof jobs exist except the approved fresh job
- persistent workers remain disabled
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is unset, false, or 0
- CT101 remains stopped and onboot=0
- PVESO Ollama remains localhost-only
- active model client count is 0 before activation
- service/timer is not already enabled or running unless the phase explicitly approves it
- no broad scheduler lane dispatch or persistent worker loop is enabled

## Rollback plan for future activation phase

E3Z-B has no live rollback because it performs no live activation.

A future activation phase must document and verify rollback before install/start.

Rollback intent:

- stop the timer first
- stop the oneshot service if active
- disable the timer
- disable the service
- reset failed unit state
- remove unit files only if the activation plan explicitly includes removal
- reload systemd only in the explicit activation or rollback phase
- verify inactive and disabled state
- verify no running scheduler process remains
- verify no running wrapper process remains
- verify no persistent workers are active
- verify CT101 remains stopped and onboot=0

Rollback must not mutate completed historical proof jobs.

## Postflight checks for future activation phase

Required postflight checks after any future scheduler service/timer proof:

- DB integrity is `ok`
- exact fresh proof job status is either completed or safely failed
- exact fresh proof job attempts are expected
- exact fresh proof job has no duplicate result rows
- jobs 29, 30, 31, and 32 remain unchanged
- no queued/running stale E3V/E3W/E3X/E3Y/E3Z proof jobs remain
- active model client count returns to 0
- one idle/loaded Ollama runner is acceptable only if active clients are 0
- service and timer state matches the activation plan
- if rollback was performed, service and timer are inactive and disabled
- persistent workers remain disabled
- CT101 remains stopped and onboot=0
- latest logs contain one bounded tick, not a loop

## E3Z-B decision

Proceed next with E3Z-C only as repo-static implementation of unit templates or harness scripts.

E3Z-C must not install, enable, start, restart, reload, or activate service/timer units.

No runtime activation should occur until a later explicit approval phase creates a fresh proof job and approves a bounded scheduler-only service/timer proof.
