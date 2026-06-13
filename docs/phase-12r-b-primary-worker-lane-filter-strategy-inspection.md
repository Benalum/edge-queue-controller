# Phase 12R-B Primary Worker Lane Filter Strategy Inspection

Phase 12R-B is an inspection-only checkpoint after Phase 12R-A.

## Baseline

Phase 12R-A proved that `primary_worker_unfiltered` means the primary CT101 worker is online but does not advertise a `queue_lane`.

The current expected live gate remains:

- `ready=false`
- `dry_run_only=true`
- reasons include:
  - `primary_worker_unfiltered`
  - `persistent_lane_workers_not_active`
- warning includes:
  - `no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk`

## Purpose

This phase inspects the worker runtime strategy before changing any service behavior.

The question is: what is the safest way to remove `primary_worker_unfiltered` later without breaking production job handling?

## Strategies under consideration

### Strategy A: Keep primary unfiltered temporarily

Keep the primary worker unfiltered as a fallback while persistent lane workers are activated and proven separately.

Pros:

- lowest immediate runtime risk
- existing production jobs continue working
- no change to CT101 primary worker claim behavior

Cons:

- readiness gate correctly remains blocked by `primary_worker_unfiltered`
- persistent lane cutover cannot be marked ready

### Strategy B: Convert primary worker to a specific lane

Set the primary worker to advertise and enforce a specific `queue_lane`.

Pros:

- removes unfiltered claim behavior
- aligns with lane-based routing

Cons:

- highest risk if any production job is not lane-tagged correctly
- may strand jobs if no no-lane fallback worker exists
- changes CT101 primary runtime behavior

### Strategy C: Use dedicated persistent lane workers plus no-lane fallback

Keep lane workers filtered for `model-tiny` and `model-small`, and provide a separate explicit no-lane fallback worker for legacy/unlaned jobs.

Pros:

- cleanest long-term safety model
- lane workers do not claim unsupported jobs
- no-lane behavior is explicit instead of accidental

Cons:

- adds one more worker role to manage
- requires careful concurrency and model limits

### Strategy D: Adjust readiness gate only after runtime proof

Do not weaken the readiness gate until worker claim behavior is proven through live checks and smoke tests.

Pros:

- safest control-plane posture
- prevents false readiness

Cons:

- requires more staged work before cutover

## Inspection findings to preserve

The primary worker service is expected to be:

- `ai-platform-laptop-queue-worker.service`

The dormant lane workers are expected to be:

- `ai-platform-laptop-queue-worker@model-tiny.service`
- `ai-platform-laptop-queue-worker@model-small.service`

Phase 12R-B must keep:

- primary worker active
- tiny lane worker inactive
- small lane worker inactive
- router rollout parked
- persistent lane cutover not ready
- dry-run protection active

## Recommendation

The safest next implementation path is not to convert the primary worker immediately.

Recommended sequence:

1. keep primary worker unfiltered for now
2. inspect/verify lane worker env files and heartbeat capabilities
3. add a read-only strategy document and smoke coverage
4. later activate persistent tiny/small lane workers in a guarded phase
5. only after lane workers prove stable, decide whether to:
   - park primary as explicit no-lane fallback, or
   - replace it with a dedicated no-lane fallback worker, or
   - convert primary to a filtered lane role

Phase 12R-B is documentation and smoke only.
