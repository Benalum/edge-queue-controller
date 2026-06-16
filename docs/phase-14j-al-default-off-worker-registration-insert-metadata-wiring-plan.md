# Phase 14J-AL default-off worker registration insert metadata wiring plan

Phase 14J-AL plans the future code patch that will wire the Phase 14J-AK helper into the worker registration INSERT path only.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `75e8ee0`
- Base tag: `controller-phase-14j-ak-default-off-worker-registration-metadata-helper-patch-2026-06-15`
- Phase 14J-AK status: complete, verified, tagged, pushed
- Repository state before 14J-AL: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- wire the helper into worker registration runtime writes
- change `/workers/heartbeat`
- change `INSERT INTO workers`
- change `UPDATE workers`
- change the `WorkerHeartbeatRequest` payload model
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

Schema presence is not runtime activation. Helper presence is not runtime activation. Insert wiring planning is not runtime activation.

## Current code state after 14J-AK

Phase 14J-AK added:

- `_phase14j_default_off_worker_registration_metadata()`

The helper is intentionally unwired. The `/workers/heartbeat` registration path still uses the legacy registration INSERT and UPDATE SQL.

## Future insert wiring goal

A later implementation phase may wire default-off metadata into the `INSERT INTO workers` path so newly registered workers receive explicit values for:

- `worker_role`
- `worker_lane`
- `accepts_lane_jobs`
- `capabilities`
- `disabled`
- `current_running_jobs`
- `state`
- `computed_health`

The first runtime wiring phase should modify only the new-worker INSERT path. It should not modify UPDATE behavior in the same phase.

## Future insert-only patch contract

The future code patch should:

1. call `_phase14j_default_off_worker_registration_metadata()` before the INSERT branch only
2. add the eight metadata columns to the INSERT column list only
3. add eight matching placeholders to the INSERT values list
4. append the helper values to the INSERT parameter tuple
5. keep `capabilities_json` unchanged
6. keep `payload.capabilities` compatibility unchanged
7. keep old heartbeat payloads accepted
8. keep `worker_lane=''`
9. keep `accepts_lane_jobs=0`
10. keep `worker_role='primary'`
11. keep scheduler lane dispatch inactive
12. keep primary-worker filtering inactive
13. avoid modifying the UPDATE path until a separate phase
14. avoid CT101 and live model calls
15. avoid job 23 mutation

## Why insert-only first

Insert-only wiring is safer than changing INSERT and UPDATE together because it proves that new worker rows can receive explicit default-off metadata without changing existing worker heartbeat behavior.

Preserve-existing UPDATE wiring should be handled later as a separate phase.

## Required future implementation smoke checks

A future code/smoke phase should prove:

- `edge_controller.py` compiles
- the helper exists exactly once
- the helper is called by the INSERT branch only
- the helper is not called by the UPDATE branch
- old heartbeat payload compatibility remains unchanged
- new worker INSERT SQL includes all eight metadata columns
- INSERT placeholders and parameters are aligned
- default insert metadata remains:
  - `worker_role='primary'`
  - `worker_lane=''`
  - `accepts_lane_jobs=0`
  - `capabilities='[]'`
  - `disabled=0`
  - `current_running_jobs=0`
  - `state='available'`
  - `computed_health=''`
- no worker becomes lane-enabled by registration alone
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent/disabled
- scheduler lane dispatch remains inactive
- primary-worker filtering remains inactive
- CT101 and live model endpoints are not called
- job 23 is not mutated

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `runtime_lane_metadata_update_writes_not_implemented`
- `registration_insert_metadata_wiring_not_implemented`
- `registration_update_preserve_existing_wiring_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AM: default-off worker registration insert metadata wiring patch, code/smoke, no runtime activation

That phase may patch source code only with explicit approval and must remain default-off.
