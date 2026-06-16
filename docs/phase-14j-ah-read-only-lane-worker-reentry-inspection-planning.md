# Phase 14J-AH read-only lane-worker re-entry inspection/planning

Phase 14J-AH records the first post-apply read-only lane-worker re-entry inspection after Phase 14J-AG applied default-off worker registry lane metadata.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `1dfc43b`
- Base tag: `controller-phase-14j-ag-guarded-default-off-worker-lane-metadata-schema-apply-2026-06-15`
- Phase 14J-AG status: complete, verified, tagged, pushed
- Repository state before 14J-AH: clean
- Phase 14J-AG apply wrapper: must not be rerun

## Hard boundaries

This phase does not:

- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- restart or reload services
- call CT101
- call live model endpoints
- mutate job 23
- activate scheduler lane dispatch
- activate primary-worker filtering
- add runtime lane metadata writes
- expose router output or enable router model selection

Schema presence is not runtime activation.

## Read-only baseline evidence

The Phase 14J-AH startup/resume inspection confirmed:

- HEAD remained `1dfc43b`
- repository remained clean
- `edge_queue.sqlite3` read-only `PRAGMA quick_check` returned `ok`
- `workers_table_count=1`
- `worker_count=0`
- `target_columns_present=8`
- `lane_enabled_worker_count=0`
- main backup existed and matched the expected size/checksum
- wrapper backup existed and matched the expected size/checksum
- Phase 14J-AG focused smoke passed

## Applied worker metadata columns observed

The read-only SQLite inspection confirmed these worker table columns and defaults:

| Column | Type | Default | Runtime meaning in this phase |
|---|---:|---:|---|
| `worker_role` | `TEXT` | `'primary'` | Schema only; not an activation signal |
| `worker_lane` | `TEXT` | `''` | Empty/default-off lane metadata |
| `accepts_lane_jobs` | `INTEGER` | `0` | Default-off lane job acceptance |
| `capabilities` | `TEXT` | `'[]'` | New metadata column; not yet runtime-written by an approved phase |
| `disabled` | `INTEGER` | `0` | Schema only; not a service enablement signal |
| `current_running_jobs` | `INTEGER` | `0` | Schema only; not scheduler activation |
| `state` | `TEXT` | `'available'` | Schema only; existing computed health behavior remains separate |
| `computed_health` | `TEXT` | `''` | Schema only; existing runtime derivation remains separate |

## Read-only source inspection findings

The inspection found the existing lane-worker work is still default-off and mostly skeleton/planning:

- scheduler pre-filter integration skeleton remains disabled by `_phase14j_lane_workers_enabled()`
- scheduler lane filter runtime call skeleton remains gated and disabled
- worker registry read paths use `SELECT * FROM workers` in several status and preview surfaces
- worker registration paths currently write legacy fields such as `capabilities_json`
- new lane metadata columns are present in the database but runtime registration write behavior has not yet been approved
- primary-worker filtering remains a blocker
- no no-lane fallback runtime cutover has been approved
- router shadow evidence remains separate from lane metadata work

## Current blockers after this inspection

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `runtime_lane_metadata_writes_not_approved`
- `registration_default_off_write_contract_not_implemented`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Smoke/checkpoint gaps to close before runtime use

Before any runtime lane metadata use, later phases should add or prove:

1. a default-off worker registration write contract
2. focused smoke coverage for registration behavior with new columns present
3. read-only proof that scheduler selection still ignores lane metadata while the gate is disabled
4. a primary-worker filtering or fallback strategy that prevents accidental lane stealing
5. rollback/stop behavior before enabling persistent lane workers
6. explicit approval before any service restart/reload or CT101 interaction

## Next safe phase

The next safe phase should remain default-off.

Recommended next step:

- Phase 14J-AI: default-off worker registration metadata write contract, docs/smoke only

That later phase should plan how registration should populate or preserve new metadata fields without enabling dispatch.

