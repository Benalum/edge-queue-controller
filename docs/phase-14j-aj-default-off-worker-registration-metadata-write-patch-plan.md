# Phase 14J-AJ default-off worker registration metadata write patch plan

Phase 14J-AJ plans the future code patch that will make worker registration write the new worker registry lane metadata columns safely and default-off.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `82a9dbb`
- Base tag: `controller-phase-14j-ai-default-off-worker-registration-metadata-write-contract-2026-06-15`
- Phase 14J-AI status: complete, verified, tagged, pushed
- Repository state before 14J-AJ: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- implement runtime registration writes
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

Schema presence is not runtime activation.

## Current state

Phase 14J-AG applied the metadata schema default-off.

Phase 14J-AH confirmed read-only re-entry evidence:

- `worker_count=0`
- `target_columns_present=8`
- `lane_enabled_worker_count=0`
- persistent lane worker flag absent/disabled
- existing scheduler lane surfaces remain gated/default-off

Phase 14J-AI recorded the worker registration metadata write contract.

## Future patch goal

A later implementation phase may update worker registration so the `workers` table receives explicit default-off metadata values when a worker registers or heartbeats.

The patch should preserve legacy behavior while making metadata state explicit.

## Proposed future registration write behavior

For both worker insert and worker update paths, the future patch should preserve or write these values:

| Column | Insert default behavior | Update behavior |
|---|---|---|
| `worker_role` | `'primary'` unless an approved payload field is later allowed | preserve existing value unless a later role update contract exists |
| `worker_lane` | `''` | preserve existing value unless a later lane opt-in contract exists |
| `accepts_lane_jobs` | `0` | preserve existing value unless a later lane activation contract exists |
| `capabilities` | sanitized JSON mirror or future canonical metadata, default `'[]'` | update only after compatibility plan with `capabilities_json` |
| `disabled` | `0` | preserve admin/runtime disable state |
| `current_running_jobs` | `0` | preserve scheduler accounting state |
| `state` | `'available'` or lifecycle-safe default | update only through a later lifecycle contract |
| `computed_health` | `''` | do not make it authoritative; existing computed health remains separate |

## Required compatibility rules

The future patch must:

1. keep old worker registration payloads accepted
2. keep `capabilities_json` working
3. avoid requiring workers to send new metadata fields
4. avoid making a worker lane-enabled by registration alone
5. avoid changing scheduler selection behavior
6. avoid filtering the primary worker
7. avoid restarting services in the same patch phase
8. avoid CT101 and live model calls
9. preserve no-job-23-mutation boundary
10. preserve `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` default-off behavior

## Proposed later implementation shape

The later code patch should be minimal and bounded:

1. Add a helper that returns safe default-off registration metadata.
2. Use that helper in the `INSERT INTO workers` path only if columns exist.
3. Use preserve-existing behavior in the `UPDATE workers` path.
4. Keep legacy `capabilities_json` untouched.
5. Add smoke coverage proving no lane-enabled workers are created.
6. Add smoke coverage proving scheduler gates remain disabled.
7. Run AG, AH, AI, and AJ regression smokes before commit.

## Required future smoke checks for the implementation phase

The future implementation smoke should prove:

- `edge_controller.py` compiles
- metadata columns exist
- default registration does not create `accepts_lane_jobs=1`
- `worker_lane` remains empty by default
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent/disabled
- scheduler lane dispatch remains inactive
- primary-worker filtering remains inactive
- CT101 and live model endpoints are not called
- job 23 is not mutated
- AG/AH/AI/AJ smokes still pass

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `runtime_lane_metadata_writes_not_implemented`
- `registration_default_off_write_patch_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AK: default-off worker registration metadata helper patch, code/smoke, no runtime activation

That phase may patch source code only if explicitly approved and must remain default-off.
