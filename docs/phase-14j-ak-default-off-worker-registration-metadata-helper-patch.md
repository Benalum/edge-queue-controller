# Phase 14J-AK default-off worker registration metadata helper patch

Phase 14J-AK adds a pure helper to `edge_controller.py` for future default-off worker registration metadata.

This phase includes a source code patch and smoke coverage, but it does not activate runtime lane behavior.

## Starting checkpoint

- Base checkpoint: `aeec84f`
- Base tag: `controller-phase-14j-aj-default-off-worker-registration-metadata-write-patch-plan-2026-06-15`
- Phase 14J-AJ status: complete, verified, tagged, pushed
- Repository state before 14J-AK: clean

## Hard boundaries

This phase does not:

- wire the helper into worker registration runtime writes
- change the `/workers/heartbeat` request model
- change worker registration payload compatibility
- change `INSERT INTO workers` registration SQL
- change `UPDATE workers` registration SQL
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

Schema presence is not runtime activation. Helper presence is not runtime activation.

## Code patch

Phase 14J-AK adds:

- `_phase14j_default_off_worker_registration_metadata()`

The helper returns this default-off metadata shape:

| Field | Value |
|---|---:|
| `worker_role` | `"primary"` |
| `worker_lane` | `""` |
| `accepts_lane_jobs` | `0` |
| `capabilities` | `"[]"` |
| `disabled` | `0` |
| `current_running_jobs` | `0` |
| `state` | `"available"` |
| `computed_health` | `""` |

## Why this helper is safe

- It is pure and deterministic.
- It does not read environment variables.
- It does not read or write the database.
- It does not call services.
- It does not alter worker registration behavior.
- It does not activate lane workers or scheduler dispatch.
- It gives later phases one safe source of truth for default-off metadata.

## Current runtime state remains unchanged

The existing worker registration path remains centered on:

- `WorkerHeartbeatRequest`
- `capabilities_json`
- `current_jobs`
- `max_concurrent_jobs`
- existing `INSERT INTO workers`
- existing `UPDATE workers`

The helper is intentionally not called by `/workers/heartbeat` in this phase.

## Required future phase before runtime writes

A later phase may wire this helper into registration writes only after explicit approval.

That future phase must prove:

- old worker registration payloads still work
- new metadata remains default-off
- no worker becomes lane-enabled just by registering
- `worker_lane` remains empty by default
- `accepts_lane_jobs` remains `0` by default
- scheduler lane dispatch remains inactive
- primary-worker filtering remains inactive
- CT101 and live model endpoints are not called
- job 23 is not mutated

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `runtime_lane_metadata_writes_not_implemented`
- `registration_default_off_write_wiring_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AL: default-off worker registration insert metadata wiring plan, docs/smoke only

That phase should still avoid runtime write wiring unless explicitly approved.
