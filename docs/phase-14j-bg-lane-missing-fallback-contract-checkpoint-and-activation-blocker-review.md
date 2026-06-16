# Phase 14J-BG lane missing fallback contract checkpoint and activation-blocker review

Phase 14J-BG records the Phase 14J-BF lane missing fallback contract decision and reviews the remaining activation blockers.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `80944e1`
- Base tag: `controller-phase-14j-bf-lane-missing-fallback-contract-decision-2026-06-15`
- Phase 14J-BF status: complete, verified, tagged, pushed
- Repository state before 14J-BG: clean

## Contract checkpoint

The selected safe contract remains:

1. No-lane jobs keep the primary/default worker path.
2. Lane-tagged jobs that require a lane worker do not silently fall back to primary workers.
3. Lane-tagged jobs with no eligible matching lane worker remain blocked/deferred.
4. `allow_primary_fallback=true` does not change production behavior yet.
5. Lane worker activation remains blocked until explicit approval and runtime-safe evidence exists.

This contract matches the current helper behavior verified by the synthetic BD smoke and recorded by BE/BF.

## Activation blocker review

| Blocker | Status | Reason |
| --- | --- | --- |
| `persistent_lane_workers_not_active` | still blocked | persistent lane workers are not enabled |
| `primary_worker_unfiltered` | still blocked | primary-worker filtering is not activated |
| `scheduler_lane_dispatch_not_active` | still blocked | scheduler lane dispatch gate remains disabled |
| `ct101_runtime_protected` | still blocked | CT101 mutation/calls remain out of scope |
| `router_rollout_parked` | still blocked | router rollout remains parked |
| `warmup_execution_disabled` | still blocked | warmup execution remains disabled |
| `rollback_smoke_pending` | still blocked | rollback has a draft/design, not an approved runtime rollback execution |
| `activation_approval_required` | still blocked | no activation approval has been requested or granted |

## Current safe state

The current safe state remains:

- worker registry metadata columns exist
- worker registry remains default-off
- no lane-enabled workers exist
- no non-empty `worker_lane` values exist
- no non-primary `worker_role` values exist
- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent or disabled
- controller service remains active and healthy
- no CT101 calls are required
- no production jobs are mutated
- scheduler runtime behavior remains default-off

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

Blocker review is not runtime activation. Contract checkpointing is not scheduler activation. Activation remains blocked.

## Recommended next safe phase

Recommended next safe phase:

- Phase 14J-BH: lane worker activation remains blocked closeout and source-update decision, docs/smoke only

That phase should decide whether to refresh the uploaded Source documents before any further runtime-adjacent work. It must not enable persistent lane workers, dispatch lanes, filter primary workers at runtime, call CT101, call models, mutate jobs, restart services, or change service environment drop-ins.
