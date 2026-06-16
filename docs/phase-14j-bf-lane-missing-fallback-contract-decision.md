# Phase 14J-BF lane missing fallback contract decision

Phase 14J-BF records the lane-missing fallback contract decision before any future persistent lane worker activation.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `d1b25e9`
- Base tag: `controller-phase-14j-be-synthetic-fallback-and-rollback-smoke-result-checkpoint-2026-06-15`
- Phase 14J-BE status: complete, verified, tagged, pushed
- Repository state before 14J-BF: clean

## Contract decision

The safe contract decision is:

1. No-lane jobs keep the primary/default worker path.
2. Lane-tagged jobs that require a lane worker must not silently fall back to the primary worker.
3. If a lane-tagged job has no eligible matching lane worker, it must remain blocked/deferred by the scheduler contract rather than being sent to the wrong worker.
4. `allow_primary_fallback=true` must not change production behavior until a later explicit fallback implementation phase adds and tests that behavior.
5. Activation remains blocked until a later phase proves lane worker availability, disabled rollback behavior, and no-lane job preservation.

This decision matches the current helper behavior verified by Phase 14J-BD and Phase 14J-BE.

## Why primary fallback is not enabled for missing lane workers yet

Primary fallback for lane-missing jobs could accidentally route specialized work to the normal/default worker.

That is unsafe until the project has:

- explicit job-level fallback semantics
- UI/API contract language for fallback behavior
- scheduler evidence that fallback cannot starve normal jobs
- rollback evidence
- synthetic and live-disabled smokes
- explicit activation approval

## Current behavior preserved

The current default-off behavior remains:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` absent/false means scheduler lane filtering stays disabled
- disabled gate returns the original worker list
- no-lane jobs preserve primary/default eligibility
- no lane-enabled workers exist
- no non-empty `worker_lane` values exist
- no non-primary `worker_role` values exist

## Future implementation requirements

A later implementation phase may choose one of these explicit strategies:

| Strategy | Meaning | Status |
| --- | --- | --- |
| strict_lane_only | lane jobs wait for a matching lane worker | selected safe default |
| explicit_primary_fallback | selected lane jobs may fall back to primary only when explicitly allowed and tested | future only |
| dedicated_no_lane_fallback_worker | normal jobs keep a dedicated no-lane worker while lane jobs use lane workers | future only |
| reject_or_defer_lane_job | lane jobs with no eligible lane worker remain queued/deferred with clear evidence | selected safe default |

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
- mutate any production job
- activate scheduler lane dispatch
- activate primary-worker filtering
- enable router model selection
- expose router output
- start warmup execution
- start persistent lane workers
- create lane worker services
- change service environment drop-ins

A contract decision is not runtime activation. Strict lane-missing behavior is not scheduler activation. Primary fallback remains unimplemented for lane-missing production jobs.

## Remaining blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `rollback_smoke_pending`
- `activation_approval_required`

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BG: lane missing fallback contract checkpoint and activation-blocker review, docs/smoke only

That phase should record this decision and review blockers. It must not enable persistent lane workers, dispatch lanes, filter primary workers at runtime, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
