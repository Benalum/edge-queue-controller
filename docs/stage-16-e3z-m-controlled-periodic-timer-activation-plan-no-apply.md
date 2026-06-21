# Stage 16 E3Z-M — Controlled Periodic Timer Activation Plan (No Apply)

Date: 2026-06-21  
Checkpoint entering this plan: `2b8306d`  
Latest activation proof tag entering this plan: `controller-stage-16-e3z-j-start-timer-one-tick-exact-fresh-job-34-restricted-pveso-helper-2026-06-21`

## Purpose

Stage 16 E3Z-M defines the next activation path after E3Z-J and E3Z-K R2:

- E3Z-J proved the first bounded systemd timer path end-to-end using exact fresh job `34`.
- E3Z-K R2 proved the platform returned to an idle, read-only, non-activated posture.
- E3Z-L R3 confirmed the real CT203 DB authority path and current queue posture.

This plan does not activate anything. It defines the safe path from one-shot/timer proof toward a controlled periodic timer window while preserving exact job allowlisting, bounded runtime, rollback, and no broad queue dispatch.

## Current verified posture

Repo and tag:

- HEAD/origin: `2b8306d`
- latest proof tag: `controller-stage-16-e3z-j-start-timer-one-tick-exact-fresh-job-34-restricted-pveso-helper-2026-06-21`

DB authority:

- CT203 authoritative SQLite path: `/var/lib/edge-queue-controller/edge_queue.sqlite3`
- `integrity=ok`
- `jobs_total=33`
- `job_results_total=14`
- `duplicate_job_results=0`
- `jobs_status_running=0`

Known job posture:

| Job | Status | Attempts | Result rows | Notes |
| --- | --- | ---: | ---: | --- |
| 23 | queued | 3 | 0 | old queued `gemma4:e4b`; do not use for timer proof |
| 24 | queued | 0 | 0 | old queued `mock/no-model`; do not use for timer proof |
| 29 | failed | 1 | 0 | hard no-rerun |
| 30 | failed | 1 | 0 | hard no-rerun |
| 31 | completed | 1 | 1 | hard no-rerun |
| 32 | completed | 1 | 1 | hard no-rerun |
| 33 | completed | 1 | 1 | hard no-rerun |
| 34 | completed | 1 | 1 | hard no-rerun; E3Z-J timer proof |

System posture entering this plan:

- CT203 `edge-queue-controller.service` active/enabled as controller API.
- `edge-queue-scheduler-one-shot.timer` inactive/disabled.
- `edge-queue-scheduler-one-shot.service` static.
- `scheduler_process_count=0`.
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=<unset>` in controller service environment.
- Scheduler service template contains `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0`.
- Scheduler service template contains `EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=0`.
- E3Z-J/R13 exact-job drop-ins absent.
- Helper remains preflight-only unless separately approved.

## Non-negotiable invariants

Users and frontend never call models directly. The canonical execution path remains:

`Frontend → Backend API → Durable Job Queue → Scheduler → Worker/Helper/Adapter → AI Model`

Authority remains:

- CT203: controller/API/queue/DB authority.
- VM200: public website/wrapper edge.
- PVESO: on-demand model/Ollama host.
- CT101: stopped and `onboot=0`.
- Persistent workers: blocked/off.

Hard no-rerun list:

- E3V-Q
- job `29`
- job `30`
- job `31`
- job `32`
- job `33`
- job `34`

The next timer proof must use a newly inserted job ID only.

## Why not broad activation yet

Broad scheduler activation is not appropriate immediately after one successful timer tick because:

1. The queue still contains old queued jobs `23` and `24`.
2. The helper path has only been proven in exact-job bounded mode.
3. The timer/service rollback path is proven, but not yet in a repeated periodic window.
4. Persistent workers must remain off.
5. User-facing companion/study/router integration depends on reliable bounded queue execution first.

## Recommended activation ladder

### E3Z-M0 — plan only

This document and its smoke test are repo-only. No live mutation.

### E3Z-M1 — pre-activation read-only guard

Before any live activation, run a read-only guard that verifies:

- repo still at expected head for the activation stage,
- CT203 is running and controller service is healthy,
- authoritative DB path is `/var/lib/edge-queue-controller/edge_queue.sqlite3`,
- DB integrity is `ok`,
- duplicate job results are `0`,
- running jobs are `0`,
- timer inactive/disabled,
- scheduler process count `0`,
- no E3Z-J/R13 exact-job drop-ins remain,
- helper is still preflight-only,
- persistent workers are unset/off,
- CT101 remains stopped/onboot=0,
- public `/system/status` and `/api/system/status` return HTTP 200,
- `/api/me` returns HTTP 401 unauthenticated.

### E3Z-M2 — insert fresh periodic-window proof jobs

This is a DB write and requires explicit approval.

Insert one or more fresh proof jobs only for this activation window. Recommended first periodic proof shape:

- insert exactly two fresh jobs,
- both use the proven small model `qwen2.5:0.5b`,
- both use deterministic proof prompts,
- both have unique expected markers such as `E3Z-M-JOB-A-OK` and `E3Z-M-JOB-B-OK`,
- record the newly assigned job IDs,
- hard-fail if the inserted IDs overlap any hard no-rerun ID,
- do not alter old queued jobs `23` or `24`.

Reason: two fresh jobs allow proving repeated timer ticks without broad queue activation.

### E3Z-M3 — install bounded activation drop-in

This is a systemd mutation and requires explicit approval.

Install a temporary drop-in for the scheduler timer/service that:

- allows only the newly inserted E3Z-M proof job IDs,
- keeps one job per tick,
- keeps max jobs per tick at `1`,
- keeps persistent workers disabled,
- enables delegation/helper execution only for the exact proof window,
- sets a strict max runtime,
- keeps helper model fixed to `qwen2.5:0.5b`,
- refuses to run if exact-job allowlist is absent,
- refuses to run if old job IDs are present in the allowlist,
- refuses broad queue scanning.

Any systemd drop-in change requires a separately approved `systemctl daemon-reload`.

### E3Z-M4 — controlled periodic timer window

This is timer activation and requires explicit approval.

Run a short bounded timer window:

- start timer only after M1/M2/M3 gates pass,
- allow the timer to tick for at most the planned proof window,
- expected result: one fresh proof job completes per tick,
- stop/disable timer immediately after the planned proof jobs complete or if any guard trips,
- do not leave timer enabled for unattended production use.

Initial target: complete exactly two fresh E3Z-M proof jobs across repeated timer ticks.

### E3Z-M5 — rollback and idle guard

This is systemd mutation and requires explicit approval.

Rollback must:

- stop timer,
- disable timer,
- ensure scheduler service is inactive/static,
- remove temporary exact-job drop-ins,
- run `systemctl daemon-reload` only with approval,
- verify `scheduler_process_count=0`,
- verify no running jobs remain,
- verify result rows for the fresh proof jobs are exactly one each,
- verify no duplicate job results,
- verify helper returned to preflight-only posture.

### E3Z-M6 — closure document

After the controlled periodic window, commit a closure document capturing:

- fresh job IDs,
- result rows,
- exact model response markers,
- timer active/disabled final state,
- rollback evidence,
- DB counts before/after,
- any failure or timeout evidence.

## Rollback plan

Rollback command family, only after explicit approval:

1. stop `edge-queue-scheduler-one-shot.timer`,
2. disable `edge-queue-scheduler-one-shot.timer`,
3. stop `edge-queue-scheduler-one-shot.service` if active,
4. remove only E3Z-M temporary drop-ins,
5. `systemctl daemon-reload`,
6. verify timer inactive/disabled,
7. verify scheduler process count zero,
8. verify helper preflight-only posture,
9. verify DB integrity and no duplicate results.

Rollback must not delete job rows or job result rows.

## Failure conditions that require abort

Abort activation if any of these are true:

- repo not at expected activation head,
- git dirty unless the dirty files are expected activation artifacts,
- CT203 not running,
- CT101 running or onboot enabled,
- DB path is not `/var/lib/edge-queue-controller/edge_queue.sqlite3`,
- DB integrity is not `ok`,
- duplicate job results greater than `0`,
- any running jobs exist before activation,
- timer already active,
- unexpected scheduler process exists,
- persistent workers enabled,
- helper run mode already enabled outside the planned activation,
- old queued jobs `23` or `24` would be selected,
- any hard no-rerun job appears in the exact-job allowlist,
- model is not the approved small proof model for this stage,
- public status is unhealthy.

## Next implementation recommendation

Do not proceed directly to broad scheduler activation or companion/study/router product integration.

Next safe stage after this plan:

`Stage 16 E3Z-N — insert two fresh controlled periodic timer proof jobs only`

That stage must be explicit DB-write approval and must produce new job IDs. It must not reuse job `34`.

## PPB checksum-gated runner policy

All downloaded PPB scripts should be invoked through a checksum gate before `bash` executes them.

Preferred command pattern after this stage lands:

```bash
# PPB_RUN
cd ~/Desktop/edge-queue-controller
source ops/ppb/ppb-sha256-runner.sh
ppb_sha256_run "$HOME/Downloads/<script-name>.sh" "<expected-sha256>"
```

Downloaded scripts must refuse to run when the SHA-256 does not exactly match the checksum provided in chat.
