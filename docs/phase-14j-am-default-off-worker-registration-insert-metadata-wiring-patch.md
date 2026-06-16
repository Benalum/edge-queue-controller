# Phase 14J-AM default-off worker registration INSERT metadata wiring patch

Phase 14J-AM wires `_phase14j_default_off_worker_registration_metadata()` into the new-worker `INSERT INTO workers` branch only.

This phase includes a source code patch and smoke coverage, but it does not activate persistent lane workers or scheduler lane dispatch.

## Starting checkpoint

- Base checkpoint: `cafb9bc`
- Base tag: `controller-phase-14j-al-default-off-worker-registration-insert-metadata-wiring-plan-2026-06-15`
- Phase 14J-AL status: complete, verified, tagged, pushed
- Repository state before 14J-AM: clean

## Hard boundaries

This phase does not:

- change the `UPDATE workers` heartbeat path
- change `WorkerHeartbeatRequest`
- require new worker payload fields
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

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT default metadata wiring is not scheduler activation.

## Code patch

The new-worker INSERT branch now calls:

- `_phase14j_default_off_worker_registration_metadata()`

It writes these explicit default-off metadata fields for newly inserted worker rows:

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

## Preserved behavior

The patch preserves:

- existing heartbeat token checks
- old worker payload compatibility
- `payload.capabilities`
- `capabilities_json`
- `current_jobs`
- `max_concurrent_jobs`
- existing UPDATE path behavior
- scheduler gate default-off behavior
- primary-worker unfiltered behavior

## Why this remains default-off

A newly inserted worker receives `accepts_lane_jobs=0` and `worker_lane=''`.

That means the worker does not become lane-enabled by registration alone.

Persistent lane dispatch remains controlled by `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`, which remains absent/disabled.

## What is intentionally not done

This phase intentionally does not:

- preserve/update metadata on existing worker heartbeat UPDATEs
- allow worker-provided lane metadata
- add lane values to the request model
- create lane workers
- start persistent lane worker services
- change scheduler selection
- modify runtime service environment

## Required smoke evidence

The Phase 14J-AM smoke verifies:

- `edge_controller.py` compiles
- the helper exists exactly once
- the helper is called exactly once
- the helper call is inside the INSERT branch
- the helper call is not inside the UPDATE branch
- INSERT includes all eight metadata columns
- INSERT includes 29 placeholders
- INSERT parameter tuple includes all eight helper-derived values
- UPDATE branch remains free of the new lane metadata writes
- persistent lane worker flag remains absent/disabled
- SQLite state remains default-off before live service reload
- AG/AH regression smokes still pass

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `registration_update_preserve_existing_wiring_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `service_not_restarted_for_am_patch`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AN: default-off worker registration UPDATE preserve-existing metadata wiring plan, docs/smoke only

That phase should still avoid runtime activation and should not restart services.
