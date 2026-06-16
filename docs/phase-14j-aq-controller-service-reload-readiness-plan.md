# Phase 14J-AQ controller service reload readiness plan

Phase 14J-AQ records the readiness plan for a future controller service reload after the default-off worker registration metadata wiring patches.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `f00ead1`
- Base tag: `controller-phase-14j-ap-worker-registration-metadata-wiring-static-validation-and-live-reload-decision-checkpoint-2026-06-15`
- Phase 14J-AP status: complete, verified, tagged, pushed
- Repository state before 14J-AQ: clean

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

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT and UPDATE metadata wiring are not scheduler activation. Reload readiness planning is not live reload.

## Current source state

The source tree contains default-off worker registration metadata wiring:

- `_phase14j_default_off_worker_registration_metadata()` exists.
- New-worker INSERT wiring exists.
- Existing-worker UPDATE preserve-existing wiring exists.
- Worker payload lane metadata is not accepted.
- Scheduler lane dispatch remains gated by `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`.
- Persistent lane workers remain disabled.

## Why a reload is separate

The code is committed and pushed, but the running controller process may still be using the pre-AO code until the service is restarted or reloaded.

That reload is intentionally separated because it touches live runtime behavior.

A later reload phase must be explicitly approved.

## Future reload phase requirements

A future reload phase should:

1. verify repo is clean
2. verify HEAD and origin/main match the approved checkpoint
3. verify the expected tag points at HEAD
4. run compile checks before reload
5. run AP/AO focused smokes before reload
6. inspect service status and environment
7. verify `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is absent/disabled
8. take a lightweight pre-reload status snapshot
9. restart or reload the controller only after explicit approval
10. verify `/health` or local health after reload
11. verify worker registry schema remains default-off
12. verify no lane-enabled workers appeared
13. verify scheduler lane dispatch remains inactive
14. avoid CT101 calls
15. avoid live model endpoint calls
16. avoid job 23 mutation

## Reload approval boundary

The future reload phase must require explicit approval before any command like:

- `systemctl restart edge-queue-controller`
- `systemctl reload edge-queue-controller`

No such command is run in Phase 14J-AQ.

## Required smoke evidence for this phase

The Phase 14J-AQ smoke verifies:

- `edge_controller.py` compiles
- AP source validation still passes
- AO source validation still passes
- the service is inspected only
- shell and service persistent lane worker flags remain absent/disabled
- SQLite target columns remain present
- no lane-enabled workers exist
- scheduler lane gate markers remain default-off
- no executable service restart/reload command exists in the AQ smoke
- source remains unchanged during AQ

## Remaining blockers after this phase

- `controller_service_reload_not_approved`
- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AR: controller service reload preflight inspection, read-only only

That phase should still not restart services unless a later explicit reload approval is given.
