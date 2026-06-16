# Phase 14J-BB no-lane fallback and rollback evidence checkpoint

Phase 14J-BB records the result of Phase 14J-BA read-only no-lane fallback and rollback evidence inspection.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `fa6b263`
- Base tag: `controller-phase-14j-az-no-lane-fallback-and-rollback-plan-2026-06-15`
- Phase 14J-BA status: complete, read-only, no repository changes
- Repository state before 14J-BB: clean

## BA result summary

Phase 14J-BA confirmed:

- `edge_controller.py` compiles
- no-lane fallback source markers exist
- disabled lane gate preserves the original worker list
- no-lane jobs preserve primary/default eligibility in the pure helper test
- lane-specific pure helper behavior selects the matching lane worker only when the gate is enabled in-process
- `edge-queue-controller` is active and enabled
- controller-only local health returned `200`
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent or disabled
- worker registry lane metadata columns remain present
- worker registry remains default-off
- no lane-enabled workers were detected
- no non-empty `worker_lane` values were detected
- no non-primary `worker_role` values were detected
- controller jobs table exists
- sampled controller jobs were all no-lane jobs
- no sampled jobs deny primary fallback
- rollback command plan was printed as a draft and not executed
- no recent traceback/sqlite/500 errors were detected
- regression smokes passed
- repository remained clean after read-only BA inspection

## Observed controller SQLite evidence from BA

- `workers_table_exists=True`
- `worker_count=0`
- `target_columns_present=8`
- `lane_enabled_worker_count=0`
- `non_default_worker_lane_count=0`
- `non_primary_worker_role_count=0`
- `jobs_table_exists=True`
- `jobs_total=22`
- job status counts:
  - `failed=1`
  - `forwarded=20`
  - `queued=1`
- recent 200 lane counts:
  - `(none)=22`
- `recent_200_no_lane_job_count=22`
- `recent_200_lane_tagged_job_count=0`
- `recent_200_requires_lane_worker_count=0`
- `recent_200_allow_primary_fallback_true_count=0`
- `recent_200_allow_primary_fallback_false_count=0`

## Rollback draft evidence

The rollback plan remains a draft and was not executed.

A later activation phase must provide an executable rollback path that can:

1. remove or override `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` so it is unset or `0`
2. reload or restart only `edge-queue-controller` after explicit approval
3. verify `/system/local-health` returns `200`
4. verify worker registry has `accepts_lane_jobs=0` and `worker_lane=''`
5. verify scheduler disabled path returns the unfiltered worker list
6. verify no CT101 mutation is required

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change worker registration SQL
- change `WorkerHeartbeatRequest`
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
- start warmup execution
- start persistent lane workers
- create lane worker services
- change service environment drop-ins

Evidence checkpointing is not runtime activation. Fallback evidence is not lane dispatch activation. Rollback draft evidence is not rollback execution.

## Remaining blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `fallback_worker_contract_pending`
- `rollback_smoke_pending`
- `synthetic_enabled_lane_smoke_pending`
- `activation_approval_required`

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BC: synthetic fallback and rollback smoke design, docs/smoke only

That phase should design synthetic tests only. It must not enable persistent lane workers, dispatch lanes, filter primary workers, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
