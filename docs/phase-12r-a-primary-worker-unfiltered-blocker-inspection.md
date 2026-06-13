# Phase 12R-A Primary Worker Unfiltered Blocker Inspection

Phase 12R-A is an inspection-only checkpoint after Phase 12Q-B.

## Current baseline

Phase 12Q-B is complete at commit `2e9604e` with tag:

`controller-phase-12q-b-conditional-no-lane-fallback-blocker-refinement-2026-06-13`

The live persistent lane cutover gate remains intentionally not ready:

- `ready=false`
- `dry_run_only=true`
- hard readiness reasons:
  - `primary_worker_unfiltered`
  - `persistent_lane_workers_not_active`
- warning:
  - `no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk`

Phase 12Q-B behavior must remain preserved: when there is no current no-lane risk, `no_no_lane_fallback_worker` is not a reason.

## Finding

`primary_worker_unfiltered` is caused by the primary worker registry capabilities not advertising a `queue_lane`.

The source logic is:

- `primary_queue_lane = capabilities.get("queue_lane")`
- `primary_worker_unfiltered = not bool(primary_queue_lane)`
- if `primary_queue_lane` is empty, the gate adds reason `primary_worker_unfiltered`

This means the controller sees the primary worker online, but the primary worker is still capable of unfiltered claims because it has no active queue-lane claim filter.

## Interpretation

This blocker is correct and should remain active until a later planned phase safely changes worker claim behavior or changes the cutover gate.

Possible future fixes include:

1. configure a worker to advertise and enforce a specific `queue_lane`
2. activate persistent lane workers for `model-tiny` and `model-small`
3. prove no unfiltered primary worker can claim lane-routed production jobs
4. refine the readiness gate only after the worker runtime and queue claim behavior are proven safe

## Safety rules

Phase 12R-A must not:

- enable router rollout
- enable persistent tiny/small workers
- change CT101 primary worker runtime
- change queue claim behavior
- remove dry-run protection
- mark persistent lane cutover ready
- remove the `primary_worker_unfiltered` blocker

## Expected state after this phase

The system should still report:

- primary worker active
- tiny lane service inactive
- small lane service inactive
- router rollout parked
- `primary_worker_unfiltered` still present
- `persistent_lane_workers_not_active` still present
- Phase 12Q-B no-lane fallback warning behavior preserved

Phase 12R-A is documentation and smoke only.

## Live gate exposure clarification

The live gate exposes primary_worker_unfiltered as a readiness reason; it does not need to expose a matching evidence.primary_worker_unfiltered field.

Phase 12R-A verifies the blocker by checking:

- the live `primary_worker_unfiltered` reason
- the live missing/null `evidence.primary_worker_queue_lane`
- the source logic that derives `primary_worker_unfiltered` from missing `capabilities.get("queue_lane")`
