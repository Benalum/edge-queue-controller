# Phase 12P-C Read-Only Gate Historical-vs-Current No-Lane Refinement

Phase 12P-C refines the `persistent_lane_cutover_readiness` gate so old completed/failed no-lane rows remain visible as evidence without permanently blocking readiness by themselves.

## Purpose

Historical no-lane rows are useful because they prove that the platform previously created no-lane `app_jobs`.

However, historical completed/failed rows should not act as a permanent blocker forever.

## Refined behavior

The gate now separates:

- current blockers
- historical evidence

## Current blockers

The gate still blocks readiness for current operational risks, including:

- `primary_worker_unfiltered`
- `persistent_lane_workers_not_active`
- `no_no_lane_fallback_worker`
- `active_jobs_missing_or_unsupported_queue_lane`
- `recent_no_lane_jobs_after_lane_contract`

## Historical evidence

Historical no-lane rows now live under:

- `evidence.historical_no_lane_jobs_detected`
- `evidence.historical_no_lane_jobs`

The old reason below should no longer appear when historical rows are only old completed/failed rows:

- `historical_no_lane_jobs_detected`

## Recent no-lane detection

The refined gate tracks the first known Stage 5P11R lane-contract job:

- `evidence.lane_contract_first_seen_at`

It then checks for no-lane jobs created after that first lane-contract timestamp:

- `blockers.recent_no_lane_jobs_after_lane_contract`
- `evidence.recent_no_lane_jobs_after_lane_contract`

If new no-lane jobs are created after the lane contract began, they remain a blocker.

## Expected current result

The current expected live result is:

- `ready=false`
- `dry_run_only=true`
- `historical_no_lane_jobs_detected` is evidence, not a readiness reason
- `recent_no_lane_jobs_after_lane_contract` is empty
- readiness remains false because:
  - primary worker is unfiltered
  - persistent lane workers are not active
  - no no-lane fallback worker exists

## Safety

This phase is read-only status refinement.

It does not:

- start services
- stop services
- enable services
- disable services
- restart workers except the controller reload needed to expose the new status logic
- claim jobs
- mutate queue rows
- change route behavior
- enable persistent lane cutover

## Smoke-required wording

historical_no_lane_jobs_detected is evidence, not a readiness reason.
