# Phase 14J-BE synthetic fallback and rollback smoke result checkpoint

Phase 14J-BE records the result of the Phase 14J-BD synthetic fallback and rollback smoke artifact.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `faaed74`
- Base tag: `controller-phase-14j-bd-synthetic-fallback-and-rollback-smoke-artifact-2026-06-15`
- Phase 14J-BD status: complete, verified, tagged, pushed
- Repository state before 14J-BE: clean

## BD result summary

Phase 14J-BD confirmed:

- `edge_controller.py` compiles
- the focused BD smoke artifact exists
- pure/in-process helper tests passed
- `disabled_equivalence` passed
- `no_lane_primary` passed
- `lane_match` passed
- `lane_missing_with_fallback_currently_blocked` passed
- `lane_missing_no_fallback_blocked` passed
- `disabled_rollback` passed
- `edge_controller.py` remained unchanged during the smoke-only phase
- worker registry metadata remained default-off
- no lane-enabled workers were detected
- no non-empty `worker_lane` values were detected
- no non-primary `worker_role` values were detected
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remained absent or disabled
- `edge-queue-controller` remained active
- controller-only local health returned `200`
- BD smoke contained no executable forbidden runtime action lines
- regression smokes passed
- repository was clean after commit, tag, and push

## Current contract note

The current helper contract intentionally keeps lane-specific missing-worker cases blocked.

The following BD cases document current safe blocked behavior, not future activation readiness:

- `lane_missing_with_fallback_currently_blocked`
- `lane_missing_no_fallback_blocked`

A later explicit fallback contract phase is still required before any activation can safely change that behavior.

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

Smoke result checkpointing is not runtime activation. In-process helper testing is not service activation. A passing synthetic smoke is not approval to enable lane workers.

## Remaining blockers

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `fallback_worker_contract_pending`
- `rollback_smoke_pending`
- `activation_approval_required`

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BF: lane missing fallback contract decision, docs/smoke only

That phase should decide whether lane-missing jobs may use primary fallback, require a no-lane fallback worker, or remain blocked until dedicated lane workers exist. It must not enable persistent lane workers, dispatch lanes, filter primary workers at runtime, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
