# Phase 12O-A Read-Only Persistent Cutover Gate Insertion Inspection

Phase 12O-A inspected where to add a read-only persistent lane cutover readiness gate.

## Result

The correct insertion point is the CT101 laptop queue worker status payload.

The future field should be added beside the existing `lane_dispatch_readiness` field:

- `registered_capacity`
- `lane_dispatch_readiness`
- `persistent_lane_cutover_readiness`

## Existing helper area

The existing read-only lane status helper is:

- `_stage5p12f_lane_dispatch_readiness(registered_capacity)`

It is marked by:

- `STAGE_5P12F_LANE_DISPATCH_READINESS_PLAN_BEGIN`
- `STAGE_5P12F_LANE_DISPATCH_READINESS_PLAN_END`

The new gate should follow the same pattern:

- read-only
- public-safe
- no service mutation
- no queue mutation
- no worker restart
- no routing behavior change

## Current live finding

Persistent lane cutover remains not ready.

Reasons:

- Primary worker is active and unfiltered.
- Tiny lane worker is inactive.
- Small lane worker is inactive.
- Tiny and small services are disabled.
- Historical no-lane jobs exist.
- There is no no-lane fallback worker.
- Current exact-lane claim support does not include a safe no-lane fallback claim mode.

## Historical no-lane risk

Historical no-lane jobs remain detectable, including `gemma4:e4b` jobs from:

- `stage_5h2_real_user_mode_aware_creation_helper`
- `stage_5f18_real_user_creation_helper`
- older rows with missing route source

This means a permanent tiny/small-only cutover could strand future no-lane jobs unless all production job creation is lane-tagged or a no-lane fallback worker exists.

## Proposed future gate shape

The future status field should look like:

- `source`: `stage_5p12o_read_only_persistent_lane_cutover_gate`
- `dry_run_only`: true
- `ready`: false
- `reasons`:
  - `primary_worker_unfiltered`
  - `historical_no_lane_jobs_detected`
  - `no_no_lane_fallback_worker`
  - `persistent_lane_services_disabled`
- `blockers`:
  - active unsupported jobs
  - historical no-lane jobs
  - primary worker queue lane
  - expected lane services
  - fallback worker presence
- `recommendation`: do not enable persistent lane cutover until production job creation is fully lane-tagged or a no-lane fallback worker exists.

## Safety state

This phase was inspection/documentation only.

No services were started.
No services were stopped.
No jobs were inserted.
No queue rows were changed.
No route behavior changed.
No worker was restarted.
No persistent cutover was enabled.
