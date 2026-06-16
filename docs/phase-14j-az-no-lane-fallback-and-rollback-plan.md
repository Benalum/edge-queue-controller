# Phase 14J-AZ no-lane fallback and rollback plan

Phase 14J-AZ records the no-lane fallback and rollback plan required before any future persistent lane worker activation.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `c5bfdc2`
- Base tag: `controller-phase-14j-ay-lane-worker-activation-evidence-result-checkpoint-2026-06-15`
- Phase 14J-AY status: complete, verified, tagged, pushed
- Repository state before 14J-AZ: clean

## Purpose

A future lane-worker activation must never strand ordinary jobs that do not have lane metadata.

The fallback plan must preserve the current safe behavior:

- Jobs without lane metadata must continue to have an eligible primary/default path.
- Primary workers must not be filtered out until a proven fallback path exists.
- Lane workers must not become required for normal queued jobs by accident.
- Rollback must be one command or one drop-in removal/revert path.
- Disabled behavior must remain equivalent to current behavior.

## Required no-lane fallback contract

Before activation, a later code phase must define and smoke-test a default-off contract for:

1. no-lane jobs
2. explicitly lane-tagged jobs
3. jobs with `requires_lane_worker=false`
4. jobs with `requires_lane_worker=true`
5. jobs allowing primary fallback
6. jobs denying primary fallback
7. unavailable lane workers
8. stale or disabled lane workers
9. primary worker preservation
10. rollback to disabled gate behavior

## Rollback plan requirements

A future activation phase must include a rollback command set that can:

- disable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`
- reload or restart only the controller service if explicitly approved
- verify controller health after rollback
- verify no lane-enabled workers remain eligible
- verify no primary-worker filtering remains active
- verify no CT101 mutation is required to return to safe behavior
- verify queued no-lane jobs still have the primary/default path

## Current blocked state

The following blockers remain active:

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

Fallback planning is not runtime activation. Rollback planning is not runtime activation. Schema presence is not runtime activation. Registration metadata wiring is not scheduler activation.

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BA: no-lane fallback and rollback evidence inspection, read-only only

That phase should inspect current source and runtime state only. It must not enable persistent lane workers, dispatch lanes, filter primary workers, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
