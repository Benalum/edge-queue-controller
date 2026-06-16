# Phase 14J-AO default-off worker registration UPDATE preserve-existing metadata wiring patch

Phase 14J-AO wires `_phase14j_default_off_worker_registration_metadata()` into the existing-worker `UPDATE workers` heartbeat branch.

This phase includes a source code patch and smoke coverage, but it does not activate persistent lane workers or scheduler lane dispatch.

## Starting checkpoint

- Base checkpoint: `77ffec0`
- Base tag: `controller-phase-14j-an-default-off-worker-registration-update-preserve-existing-metadata-wiring-plan-2026-06-15`
- Phase 14J-AN status: complete, verified, tagged, pushed
- Repository state before 14J-AO: clean

## Hard boundaries

This phase does not:

- change `WorkerHeartbeatRequest`
- require new worker payload fields
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

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT and UPDATE default metadata wiring are not scheduler activation.

## Code patch

The existing-worker UPDATE branch now calls:

- `_phase14j_default_off_worker_registration_metadata()`

The UPDATE branch uses preserve-existing assignments:

- `worker_role = COALESCE(worker_role, ?)`
- `worker_lane = COALESCE(worker_lane, ?)`
- `accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)`
- `capabilities = COALESCE(capabilities, ?)`
- `disabled = COALESCE(disabled, ?)`
- `current_running_jobs = COALESCE(current_running_jobs, ?)`
- `state = COALESCE(state, ?)`
- `computed_health = COALESCE(computed_health, ?)`

The helper supplies default-off fallback values only when existing metadata is NULL.

## Default-off fallback values

| Field | Fallback |
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
- AM INSERT metadata wiring
- scheduler gate default-off behavior
- primary-worker unfiltered behavior

## Why this remains default-off

The UPDATE branch does not consume lane metadata from worker payloads.

The UPDATE branch does not set `accepts_lane_jobs=1`.

The UPDATE branch does not set a non-empty `worker_lane`.

The UPDATE branch only fills NULL metadata with default-off fallback values.

Persistent lane dispatch remains controlled by `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`, which remains absent/disabled.

## What is intentionally not done

This phase intentionally does not:

- restart the service to load the code
- create lane workers
- start persistent lane worker services
- change scheduler selection
- modify runtime service environment
- expose lane metadata controls to workers
- let worker heartbeat payloads opt into lanes

## Required smoke evidence

The Phase 14J-AO smoke verifies:

- `edge_controller.py` compiles
- the helper exists exactly once
- the helper is called exactly twice at runtime sites
- one helper call is inside the INSERT branch
- one helper call is inside the UPDATE branch
- INSERT metadata wiring remains unchanged from AM
- UPDATE preserve-existing assignments exist for all eight metadata columns
- UPDATE does not consume worker-provided lane metadata
- persistent lane worker flag remains absent/disabled
- SQLite state remains default-off before live service reload
- AG/AH regression smokes still pass

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `service_not_restarted_for_registration_metadata_wiring`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AP: worker registration metadata wiring static validation and live-reload decision checkpoint, docs/smoke only

That phase should inspect whether to reload the controller service later, but should not restart services unless explicitly approved.
