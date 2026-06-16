# Phase 14J-AP worker registration metadata wiring static validation and live-reload decision checkpoint

Phase 14J-AP records the post-AO static validation checkpoint for worker registration metadata wiring.

This phase is documentation and smoke only.

## Starting checkpoint

- Base checkpoint: `be0b734`
- Base tag: `controller-phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch-2026-06-15`
- Phase 14J-AO status: complete, verified, tagged, pushed
- Repository state before 14J-AP: clean

## Hard boundaries

This phase does not:

- change `edge_controller.py`
- change `/workers/heartbeat`
- change `INSERT INTO workers`
- change `UPDATE workers`
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

Schema presence is not runtime activation. Helper presence is not runtime activation. INSERT and UPDATE metadata wiring are not scheduler activation. Static validation is not live reload.

## Current code state after 14J-AO

The worker registration metadata helper exists:

- `_phase14j_default_off_worker_registration_metadata()`

The helper returns:

- `worker_role='primary'`
- `worker_lane=''`
- `accepts_lane_jobs=0`
- `capabilities='[]'`
- `disabled=0`
- `current_running_jobs=0`
- `state='available'`
- `computed_health=''`

The new-worker INSERT branch uses the helper to write explicit default-off metadata.

The existing-worker UPDATE branch uses the helper with preserve-existing `COALESCE(column, ?)` assignments.

## Static validation decision

Phase 14J-AP validates that the source tree is internally consistent after AO.

Expected static result:

- helper exists exactly once
- helper is called in the INSERT branch once
- helper is called in the UPDATE branch once
- INSERT metadata columns and placeholders remain aligned
- UPDATE preserve-existing metadata assignments are present
- worker heartbeat payload still does not accept lane metadata
- persistent lane workers remain disabled
- scheduler lane dispatch remains gated/default-off

## Live-reload decision checkpoint

The source patch is committed and pushed, but this phase does not restart or reload the controller service.

A later explicit service-reload phase is required before the running controller process can be expected to execute the AO code path.

That later phase must be approved separately and should include:

- pre-reload repo and service inspection
- service environment inspection
- compile check
- focused smokes before reload
- `systemctl restart edge-queue-controller` or equivalent only after explicit approval
- post-reload health check
- post-reload worker registration compatibility check
- confirmation that `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent/disabled
- confirmation that scheduler lane dispatch remains inactive
- no CT101 mutation
- no live model endpoint call
- no job 23 mutation

## Required smoke evidence for this phase

The Phase 14J-AP smoke verifies:

- `edge_controller.py` compiles
- helper exists exactly once
- helper has exact default-off return values
- helper has one INSERT call and one UPDATE call
- INSERT branch still has 29 columns and 29 placeholders
- UPDATE branch still has preserve-existing assignments for all eight metadata columns
- worker payload lane metadata is not consumed
- source remains unchanged during AP
- DB remains default-off
- persistent lane worker flag remains absent/disabled
- scheduler lane gate markers remain default-off
- no service restart/reload is performed

## Remaining blockers after this phase

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `scheduler_lane_dispatch_not_active`
- `ct101_runtime_protected`
- `router_rollout_parked`
- `warmup_execution_disabled`
- `service_not_restarted_for_registration_metadata_wiring`

## Next safe phase

Recommended next safe phase:

- Phase 14J-AQ: controller service reload readiness plan, docs/smoke only

That phase should still not restart services. A later service reload needs explicit approval.
