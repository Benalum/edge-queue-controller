# Phase 14J-F Persistent Lane Worker Scheduler Integration Readiness

Phase 14J-F is a docs/smoke-only readiness audit before any scheduler integration for persistent lane workers.

## Scope

This phase audits the future scheduler integration boundary.

This phase does not change scheduler behavior.

This phase does not wire lane helpers into scheduler code.

This phase does not filter the primary worker.

This phase does not change worker registration.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Checkpoint

Latest completed checkpoint before this phase:

- Phase 14J-E added default-off persistent lane worker helper skeletons.
- Phase 14J-D planned the helper boundary.
- Phase 14J-C defined the eligibility contract.
- Phase 14J-B inspected worker/scheduler surfaces.
- Phase 14J-A reopened persistent lane worker blocker re-entry.

## Current Helper State

The following helper skeletons exist:

- `_phase14j_lane_workers_enabled()`
- `_phase14j_job_lane_metadata(job)`
- `_phase14j_worker_lane_metadata(worker)`
- `_phase14j_worker_eligible_for_job(worker, job)`
- `_phase14j_filter_workers_for_lane(workers, job)`

They are not wired into scheduler behavior yet.

## Scheduler Integration Surfaces

Future scheduler integration must inspect and protect these existing surfaces:

- `select_best_worker_for_job`
- `score_worker_for_job`
- `estimate_job_requirements`
- `scheduler_preview`
- worker registry loading paths
- worker capability checks
- fallback handling
- disabled/stale/unhealthy/offline handling

## Required Future Integration Shape

A later integration phase should be narrow.

Expected shape:

1. Keep existing scheduler behavior unchanged when `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is disabled.
2. Add a small pre-filter or eligibility check only behind the default-off gate.
3. Preserve legacy fallback when the gate is disabled.
4. Preserve worker scoring order unless a later scoring phase explicitly changes it.
5. Preserve public API and browser response shape.
6. Do not call models.
7. Do not mutate CT101.

## Future Primary Worker Filtering Boundary

Primary/default worker filtering must be separate from the first scheduler integration step unless explicitly approved.

The first integration should prove:

- disabled gate = no behavior change,
- helper call is safely isolated,
- fallback remains unchanged,
- no browser output changes,
- no worker registration changes.

## Required Static Validation Before Integration

Before adding scheduler integration code, a later phase must statically verify:

- exact function insertion point,
- no duplicate helper calls,
- disabled gate pass-through,
- no live model calls,
- no CT101 mutation,
- no job 23 mutation,
- no secret exposure,
- no raw prompt/message/body exposure,
- no router activation,
- no warmup execution enablement.

## Candidate Next Phase

After this readiness audit, the next safe phase can be one of:

- Phase 14J-G: disabled scheduler integration plan, docs/smoke only.
- Phase 14J-G: narrow default-off scheduler pre-filter skeleton, runtime code but disabled by default.

The safer path is one more docs/smoke-only plan before wiring scheduler behavior.
