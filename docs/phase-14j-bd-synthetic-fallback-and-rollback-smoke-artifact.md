# Phase 14J-BD synthetic fallback and rollback smoke artifact

Phase 14J-BD adds a focused smoke artifact for pure/in-process synthetic lane fallback and rollback checks.

This phase is smoke-only plus documentation. It does not change runtime controller code.

## Starting checkpoint

- Base checkpoint: `efa4804`
- Base tag: `controller-phase-14j-bc-synthetic-fallback-and-rollback-smoke-design-2026-06-15`
- Phase 14J-BC status: complete, verified, tagged, pushed
- Repository state before 14J-BD: clean

## What this smoke artifact proves

The focused smoke artifact proves the current helper behavior without activating runtime lane workers:

- disabled gate behavior preserves the original worker list
- no-lane normal jobs preserve primary/default eligibility in pure helper tests
- lane-tagged jobs can select a matching lane worker only inside a temporary Python process
- lane-tagged jobs with no matching lane worker remain blocked under the current helper contract
- lane-tagged jobs denying primary fallback remain blocked
- disabled rollback behavior restores the original unfiltered worker list
- the service environment remains default-off
- worker registry metadata remains default-off
- controller health remains available

## Important current-contract note

The current helper contract does not yet implement a no-lane production fallback worker or a lane-missing primary fallback exception for lane-specific jobs.

That means this smoke intentionally verifies the current safe blocked behavior:

- `lane_missing_with_fallback_currently_blocked`
- `lane_missing_no_fallback_blocked`

This keeps future activation blocked until a later explicit fallback contract phase changes and tests that behavior.

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change worker registration SQL
- change `WorkerHeartbeatRequest`
- rerun `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` in systemd or the shell
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

The only enabled-gate checks are isolated inside a short-lived Python process. In-process helper testing is not service activation. Smoke artifact creation is not runtime activation.

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

- Phase 14J-BE: synthetic fallback and rollback smoke result checkpoint, docs/smoke only

That phase should record the BD smoke result. It must not enable persistent lane workers, dispatch lanes, filter primary workers at runtime, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
