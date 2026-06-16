# Phase 14J-AN default-off worker registration UPDATE preserve-existing metadata wiring plan

Phase 14J-AN plans the future code patch that may update the existing-worker `UPDATE workers` heartbeat path to preserve existing worker lane metadata safely.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `07b4123`
- Base tag: `controller-phase-14j-am-default-off-worker-registration-insert-metadata-wiring-patch-2026-06-15`
- Phase 14J-AM status: complete, verified, tagged, pushed
- Repository state before 14J-AN: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change `INSERT INTO workers`
- change `UPDATE workers`
- wire new UPDATE metadata writes
- change `WorkerHeartbeatRequest`
- allow worker-provided lane metadata
- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- activate scheduler lane dispatch
- activate primary-worker filtering
- enable router model selection
- expose router output

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT default metadata wiring is not scheduler activation. UPDATE wiring planning is not runtime activation.

## Current state after 14J-AM

Phase 14J-AM wired `_phase14j_default_off_worker_registration_metadata()` into the new-worker INSERT branch only.

New worker INSERT rows now receive explicit default-off metadata:

- `worker_role='primary'`
- `worker_lane=''`
- `accepts_lane_jobs=0`
- `capabilities='[]'`
- `disabled=0`
- `current_running_jobs=0`
- `state='available'`
- `computed_health=''`

The existing-worker UPDATE path remains legacy/unwired.

## Future UPDATE preserve-existing goal

A later implementation phase may update the existing-worker UPDATE branch so metadata columns are preserved safely on heartbeat updates.

The goal is not to make workers lane-enabled.

The goal is only to keep metadata stable and explicit as the worker row continues to heartbeat.

## Future UPDATE patch contract

A later code patch should:

1. keep old heartbeat payloads accepted
2. keep `WorkerHeartbeatRequest` unchanged
3. keep `capabilities_json` unchanged
4. not allow workers to set lane metadata through heartbeat payloads
5. not update `worker_role` from request data
6. not update `worker_lane` from request data
7. not update `accepts_lane_jobs` from request data
8. not update `disabled` from request data
9. not update scheduler accounting from request data
10. preserve existing metadata values already on the row
11. use default-off fallback values only when existing metadata is NULL
12. preserve `accepts_lane_jobs=0` unless a later explicit lane activation phase changes it
13. preserve `worker_lane=''` unless a later explicit lane activation phase changes it
14. keep scheduler lane dispatch inactive
15. keep primary-worker filtering inactive
16. avoid CT101 and live model calls
17. avoid job 23 mutation

## Proposed future UPDATE shape

The future patch should be minimal and bounded.

A safe pattern would be to extend the UPDATE SET list with preserve-existing assignments such as:

- `worker_role = COALESCE(worker_role, ?)`
- `worker_lane = COALESCE(worker_lane, ?)`
- `accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)`
- `capabilities = COALESCE(capabilities, ?)`
- `disabled = COALESCE(disabled, ?)`
- `current_running_jobs = COALESCE(current_running_jobs, ?)`
- `state = COALESCE(state, ?)`
- `computed_health = COALESCE(computed_health, ?)`

The parameter values should come from `_phase14j_default_off_worker_registration_metadata()`.

This keeps existing metadata stable while ensuring NULL values become default-off.

## Required future implementation smoke checks

A future code/smoke phase should prove:

- `edge_controller.py` compiles
- the helper exists exactly once
- the helper is called by INSERT and UPDATE only
- INSERT metadata wiring remains unchanged
- UPDATE preserve-existing assignments exist for all eight metadata columns
- UPDATE does not consume worker-provided lane metadata
- old heartbeat payload compatibility remains unchanged
- `accepts_lane_jobs` remains default-off
- `worker_lane` remains empty by default
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent/disabled
- scheduler lane dispatch remains inactive
- primary-worker filtering remains inactive
- CT101 and live model endpoints are not called
- job 23 is not mutated

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `registration_update_preserve_existing_wiring_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `service_not_restarted_for_registration_metadata_wiring`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AO: default-off worker registration UPDATE preserve-existing metadata wiring patch, code/smoke, no runtime activation

That phase may patch source code only with explicit approval and must not restart services.
