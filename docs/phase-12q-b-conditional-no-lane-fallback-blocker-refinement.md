# Phase 12Q-B Conditional No-Lane Fallback Blocker Refinement

Phase 12Q-B refines the read-only `persistent_lane_cutover_readiness` gate so no-lane fallback absence is only a hard blocker when current no-lane risk exists.

## Purpose

Phase 12Q-A proved that:

- production real-user `app_jobs` creation is lane-tagged
- no active unsupported/no-lane `app_jobs` exist
- no no-lane `app_jobs` were created after the Stage 5P11R lane contract began
- remaining no-lane producers are synthetic/test support paths

Because of that, a no-lane fallback worker should not be a permanent hard blocker when there is no current production no-lane risk.

## Refined behavior

The gate still reports fallback worker state, but separates warning/evidence from hard readiness blockers.

The reason below should only appear when current no-lane risk exists and no fallback worker exists:

- `no_no_lane_fallback_worker`

Current no-lane risk means one of these exists:

- active unsupported/no-lane `app_jobs`
- recent no-lane `app_jobs` after the lane contract began

## Evidence fields

The gate now exposes:

- `evidence.no_lane_fallback_worker_present`
- `evidence.no_lane_fallback_worker_candidates`
- `evidence.no_lane_fallback_worker_required`
- `evidence.no_lane_fallback_requirement_source`

## Warning field

When no fallback worker exists but no current no-lane risk exists, the gate may include:

- `warnings=["no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk"]`

This warning is informational only and should not block readiness.

## Expected current result

The current expected live result is:

- `ready=false`
- `dry_run_only=true`
- `no_no_lane_fallback_worker` is not a reason
- `evidence.no_lane_fallback_worker_required=false`
- `evidence.no_lane_fallback_requirement_source=not_required_without_current_no_lane_risk`
- readiness remains false because:
  - primary worker is unfiltered
  - persistent lane workers are not active

## Safety

This phase is read-only status refinement.

It does not:

- start services
- stop services
- enable services
- disable services
- claim jobs
- mutate queue rows
- change route behavior
- enable persistent lane cutover

## Smoke-required readiness clarification

Phase 12Q-B makes the no-lane fallback blocker conditional.

When there is no current no-lane risk, `no_no_lane_fallback_worker is not a reason` for hard readiness failure. In that state, the gate should report a warning instead, such as `no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk`, while keeping `evidence.no_lane_fallback_worker_required=false`.
