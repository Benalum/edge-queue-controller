# Stage 16 E3Z-D — Activation and Rollback Plan, No Live Mutation

## Phase status

MUTATION_SCOPE: repo docs/smoke/commit/tag/push only.

E3Z-D is a planning phase only. It documents a future bounded scheduler service/timer activation path and rollback path.

E3Z-D does not:

- write the DB
- insert a job
- claim a job
- mutate job status
- execute the scheduler
- execute the wrapper
- call a model endpoint
- pull a model
- install service files
- enable/start/restart/reload services
- install timer files
- enable/start/restart/reload timers
- run `systemctl daemon-reload`
- activate the scheduler
- activate persistent workers
- start CT101
- mutate CTs, VMs, Cloudflare, DNS, tunnels, or private storage

## Checkpoint entering E3Z-D

- Previous HEAD/origin/main: `5f8104d`
- Previous tag: `controller-stage-16-e3z-c-static-scheduler-service-timer-artifacts-no-install-no-start-2026-06-21`
- Static harness: `ops/scheduler/stage-16-e3z-scheduler-tick.sh`
- Static service template: `ops/systemd/edge-queue-scheduler-one-shot.service`
- Static timer template: `ops/systemd/edge-queue-scheduler-one-shot.timer`
- DB authority: CT203
- DB path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- Closed historical proof jobs: job 29, job 30, job 31, job 32
- Persistent scheduler: blocked
- Persistent workers: disabled
- CT101: stopped and onboot=0

## Why E3Z-D exists

E3Z-C created static repo artifacts only. E3Z-D does not install them. It defines the exact future split between fresh proof job insertion, disabled systemd file installation, bounded timer activation, rollback, and postflight.

## Future activation split

The future activation remains split into explicit approval phases.

### E3Z-E — optional source refresh and handoff

Recommended before live systemd activation.

### E3Z-F — fresh proof job insertion

Requires explicit DB-write approval.

Suggested future approval token:

```text
APPROVE_STAGE_16_E3Z_F_INSERT_ONE_FRESH_TIMER_PROOF_JOB_ONLY
```

Purpose:

- insert exactly one fresh queued proof job
- do not use job 29, job 30, job 31, or job 32
- verify result rows start at 0
- verify attempts start at 0
- verify job type and model match the activation plan

Recommended future job type:

```text
stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke
```

Recommended future model:

```text
qwen2.5:0.5b
```

### E3Z-G — install service/timer files disabled, no start

Requires explicit service-file mutation approval.

Suggested future approval token:

```text
APPROVE_STAGE_16_E3Z_G_INSTALL_SCHEDULER_TIMER_FILES_DISABLED_NO_START
```

Purpose:

- copy static service template to `/etc/systemd/system/edge-queue-scheduler-one-shot.service`
- copy static timer template to `/etc/systemd/system/edge-queue-scheduler-one-shot.timer`
- create `/etc/edge-queue-controller/scheduler-one-shot.env`
- keep timer disabled
- keep service inactive
- do not start timer
- do not start service
- do not run scheduler
- do not call model

### E3Z-H — bounded scheduler-only timer activation

Requires explicit scheduler activation approval.

Suggested future approval token:

```text
APPROVE_STAGE_16_E3Z_H_START_TIMER_ONE_TICK_ONE_FRESH_JOB_SCHEDULER_ONLY
```

Purpose:

- enable/start only the timer for a bounded proof window
- process exactly one fresh proof job
- keep persistent workers disabled
- keep CT101 stopped
- immediately postflight and roll back or leave timer state exactly as approved

## Future environment file contract

Future environment file path:

```text
/etc/edge-queue-controller/scheduler-one-shot.env
```

Future required contents:

```text
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
APC_STAGE16_E3Z_SCHEDULER_TIMER_APPROVAL=APPROVE_STAGE_16_E3Z_TIMER_ONE_JOB_PER_TICK_FRESH_PROOF_ONLY
```

The env file must not contain secrets.

## Future preflight gates before activation

A future activation phase must fail closed unless all gates pass:

- explicit activation approval token is present
- HEAD and origin/main match the expected activation checkpoint
- working tree is clean
- DB path is exactly `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- DB integrity is `ok`
- duplicate `job_results` count is zero
- exact fresh proof job id is present
- exact job id is not 29, 30, 31, or 32
- exact job is queued
- exact job attempts are 0
- exact job result rows are 0
- exact job type is `stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke`
- exact job model is `qwen2.5:0.5b`
- no other queued/running E3V/E3W/E3X/E3Y/E3Z proof jobs exist
- static harness exists and passes syntax validation
- installed service file matches repo template
- installed timer file matches repo template
- env file exists, is root-owned, and is not world-readable
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is unset, false, or `0`
- persistent workers are disabled
- CT101 is stopped and onboot=0
- PVESO Ollama is localhost-only
- active model client count is 0 before activation
- timer is not already enabled or active unless explicitly expected
- service is not already running
- no scheduler process is already running
- no wrapper process is already running

## Future bounded activation sequence

The future activation sequence should be operator-driven and bounded:

```text
1. Run preflight.
2. Verify fresh proof job.
3. Install/copy service/timer/env files only in approved phase.
4. Reload systemd only in approved phase.
5. Enable/start timer only in approved activation phase.
6. Observe exactly one timer tick or one service invocation.
7. Verify exactly one fresh job outcome.
8. Stop/disable timer or leave state only if the activation phase explicitly approves that final state.
9. Run postflight.
```

The service must remain `Type=oneshot`.

No daemon loop is allowed.

No broad queue drain is allowed.

## Future rollback commands

These are documentation-only commands in E3Z-D. They must not be executed in E3Z-D.

```bash
sudo systemctl stop edge-queue-scheduler-one-shot.timer
sudo systemctl stop edge-queue-scheduler-one-shot.service || true
sudo systemctl disable edge-queue-scheduler-one-shot.timer
sudo systemctl disable edge-queue-scheduler-one-shot.service || true
sudo systemctl reset-failed edge-queue-scheduler-one-shot.timer edge-queue-scheduler-one-shot.service || true
sudo systemctl daemon-reload
```

Optional removal, only if the explicit rollback phase approves removal:

```bash
sudo rm -f /etc/systemd/system/edge-queue-scheduler-one-shot.timer
sudo rm -f /etc/systemd/system/edge-queue-scheduler-one-shot.service
sudo rm -f /etc/edge-queue-controller/scheduler-one-shot.env
sudo systemctl daemon-reload
```

## Future rollback verification

A future rollback verification must confirm:

- timer is inactive
- timer is disabled
- service is inactive
- service is disabled or static as expected
- no scheduler process is running
- no timeout-safe wrapper process is running
- no broad scheduler process is running
- persistent workers remain disabled
- CT101 remains stopped and onboot=0
- jobs 29, 30, 31, and 32 remain unchanged
- fresh proof job has a documented final state
- no duplicate result rows exist
- active model client count is 0

## Future postflight after bounded activation

A future activation postflight must confirm:

- DB integrity is `ok`
- exact fresh proof job status is completed or safely failed
- exact fresh proof job attempts are expected
- exact fresh proof job result rows are exactly 1 if completed
- no duplicate `job_results` exist
- jobs 29, 30, 31, and 32 are unchanged
- no queued/running stale Stage 16 proof jobs remain
- active model client count returns to 0
- PVESO Ollama remains localhost-only
- persistent workers remain disabled
- CT101 remains stopped and onboot=0
- service/timer final state matches the approved activation plan

## E3Z-D decision

E3Z-D does not authorize live activation.

Next safe options:

1. E3Z-E source refresh and new-chat handoff, recommended before activation.
2. E3Z-F fresh proof job insertion plan with explicit DB-write approval.
3. E3Z-G install service/timer files disabled, with explicit service mutation approval.
4. E3Z-H bounded scheduler-only timer activation, with explicit scheduler activation approval.

Persistent workers remain blocked until scheduler-only service/timer activation is proven safe.
