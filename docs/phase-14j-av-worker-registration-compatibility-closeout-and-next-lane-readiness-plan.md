# Phase 14J-AV worker registration compatibility closeout and next-lane-readiness plan

Phase 14J-AV closes out the default-off worker registration metadata compatibility sequence after post-reload validation.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `24f6242`
- Base tag: `controller-phase-14j-au-post-reload-compatibility-result-checkpoint-2026-06-15`
- Phase 14J-AU status: complete, verified, tagged, pushed
- Repository state before 14J-AV: clean

## Closeout result

The worker registration metadata path is now safely prepared in default-off form:

- SQLite worker registry lane metadata columns exist.
- The registration helper returns safe default-off metadata.
- New worker INSERT metadata wiring exists.
- Existing worker UPDATE preserve-existing metadata wiring exists.
- Controller service was restarted in Phase 14J-AS after explicit approval.
- Post-reload compatibility inspection passed in Phase 14J-AT.
- Post-reload result checkpoint was committed in Phase 14J-AU.

## Still not activated

This closeout does not mean lane workers are active.

The following remain blocked:

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

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

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT and UPDATE metadata wiring are not scheduler activation. A successful reload is not lane dispatch activation.

## Next lane-readiness plan

Before any future activation, the project needs a read-only readiness matrix that answers:

1. Which jobs are currently unlaned?
2. Which jobs would require a lane worker?
3. Which fallback path protects normal jobs?
4. Which worker registry rows would be eligible if lane dispatch were enabled?
5. Which service environment flags would be required?
6. Which rollback command disables the feature?
7. Which smoke proves disabled behavior remains unchanged?
8. Which smoke proves enabled synthetic behavior works without touching real jobs?

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-AW: lane worker activation preconditions matrix, docs/smoke only

That phase should still not enable persistent lane workers, dispatch lanes, filter primary workers, call CT101, call models, or mutate jobs.
