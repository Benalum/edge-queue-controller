# Phase 14J-AI default-off worker registration metadata write contract

Phase 14J-AI records the future worker registration metadata write contract after Phase 14J-AG applied default-off worker registry lane metadata and Phase 14J-AH recorded read-only re-entry inspection evidence.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `9e744f3`
- Base tag: `controller-phase-14j-ah-read-only-lane-worker-reentry-inspection-planning-2026-06-15`
- Phase 14J-AH status: complete, verified, tagged, pushed
- Repository state before 14J-AI: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- activate scheduler lane dispatch
- activate primary-worker filtering
- add runtime lane metadata writes
- change worker registration runtime behavior
- expose router output or enable router model selection

Schema presence is not runtime activation.

## Current observed state before this contract

The previous 14J-AH read-only inspection confirmed:

- `edge_queue.sqlite3` exists and passes read-only `PRAGMA quick_check`
- `workers` table exists
- `worker_count=0`
- `target_columns_present=8`
- `lane_enabled_worker_count=0`
- Phase 14J-AG smoke passed
- Phase 14J-AH smoke passed
- persistent lane workers remain absent/disabled

## Worker metadata columns now available

Phase 14J-AG added these default-off worker registry columns:

| Column | Current DB default | Future registration write contract |
|---|---:|---|
| `worker_role` | `'primary'` | write explicit role only after gated registration patch; default should remain `primary` unless a worker opts into another approved role |
| `worker_lane` | `''` | write empty string unless a later approved worker explicitly advertises a safe lane |
| `accepts_lane_jobs` | `0` | write `0` unless a later gated phase explicitly allows lane job acceptance |
| `capabilities` | `'[]'` | write sanitized JSON metadata only after the contract is implemented |
| `disabled` | `0` | preserve default unless an admin/runtime disable contract is separately approved |
| `current_running_jobs` | `0` | preserve default; scheduler accounting changes require a separate gate |
| `state` | `'available'` | preserve default unless a later lifecycle write contract is approved |
| `computed_health` | `''` | do not trust as an activation signal; runtime computed health behavior remains separate |

## Existing registration surface noted by inspection

The current registration code path still centers on legacy worker registration fields such as:

- `worker_id`
- `base_url`
- `status`
- `last_heartbeat`
- `capabilities_json`
- `max_concurrent_jobs`

The new lane metadata columns exist in the database but are not yet approved as runtime registration write targets.

## Future default-off registration patch contract

A later implementation phase may patch worker registration writes only if it follows this contract:

1. Keep registration default-off.
2. Do not allow a worker to become lane-enabled just by registering.
3. Preserve `accepts_lane_jobs=0` unless an explicit later approval enables a controlled lane worker.
4. Preserve `worker_lane=''` unless a later controlled lane-worker phase validates the lane value.
5. Preserve the primary worker as unfiltered until a separate primary-worker filtering/fallback phase is approved.
6. Treat `capabilities_json` and new `capabilities` as separate compatibility surfaces until a migration plan is approved.
7. Add focused smoke tests proving old-style worker registration still works.
8. Add focused smoke tests proving new metadata columns remain default-off after registration.
9. Do not activate scheduler lane dispatch in the same phase as a registration write patch.
10. Do not call CT101 or live model endpoints as part of the contract implementation.

## Required future smoke coverage before runtime writes

Before any worker registration runtime patch is allowed, a later phase should include smoke checks for:

- old registration payload compatibility
- explicit default values for all new metadata columns
- no lane-enabled worker rows after default registration
- no scheduler behavior change while `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is disabled
- no primary-worker filtering activation
- no CT101/model calls
- repo clean, compile pass, and AG/AH regression smokes passing

## Blockers that remain after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `runtime_lane_metadata_writes_not_implemented`
- `registration_default_off_write_patch_not_approved`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AJ: default-off worker registration metadata write patch plan, docs/smoke only

That phase should still avoid code mutation unless explicitly approved. The first runtime patch should be separate, minimal, default-off, and backed by focused smoke tests.

