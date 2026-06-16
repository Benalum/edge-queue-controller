# Phase 14J-G Disabled Scheduler Integration Plan

Phase 14J-G is a docs/smoke-only plan for the first future scheduler integration of persistent lane worker helpers.

## Scope

This phase plans the disabled scheduler integration boundary.

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

- Phase 14J-F audited scheduler integration readiness.
- Phase 14J-E added default-off persistent lane worker helper skeletons.
- Phase 14J-D planned helper implementation.
- Phase 14J-C defined eligibility contract.
- Phase 14J-B inspected worker/scheduler surfaces.
- Phase 14J-A reopened persistent lane worker blocker re-entry.

## Existing Helpers

The following helpers exist but are not wired into scheduler behavior:

- `_phase14j_lane_workers_enabled()`
- `_phase14j_job_lane_metadata(job)`
- `_phase14j_worker_lane_metadata(worker)`
- `_phase14j_worker_eligible_for_job(worker, job)`
- `_phase14j_filter_workers_for_lane(workers, job)`

## Candidate Future Integration Point

The likely first integration point is `select_best_worker_for_job`.

Reason:

- it is the central worker choice surface,
- it can receive candidate workers before final scoring,
- it can remain pass-through when the gate is disabled,
- it can preserve current scoring and fallback order when disabled.

`score_worker_for_job` should not be changed in the first integration step unless a later scoring phase explicitly approves it.

Plain marker: score_worker_for_job should not be changed

## Future Disabled Integration Shape

A future runtime phase may add a tiny guarded block inside `select_best_worker_for_job`:

1. Build the existing worker candidate list exactly as before.
2. Check `_phase14j_lane_workers_enabled()`.
3. If disabled, skip lane filtering and preserve current behavior.
4. If enabled, call `_phase14j_filter_workers_for_lane(...)` on the candidate list.
5. If filtering returns no candidates, use a bounded fallback decision only if explicitly approved.
6. Continue existing scoring and selection after the guarded block.

## Required No-Behavior-Change Rule

When `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is disabled:

- worker candidate list must remain unchanged,
- worker scoring must remain unchanged,
- worker assignment must remain unchanged,
- fallback behavior must remain unchanged,
- browser/API output must remain unchanged,
- queue/job creation must remain unchanged,
- worker registration must remain unchanged.

## Primary Worker Filtering Boundary

Primary/default worker filtering remains separate.

The first scheduler integration must not permanently block the primary/default worker unless a later phase explicitly approves primary filtering.

## Future Smoke Requirements

The future runtime integration phase must include static smokes proving:

- scheduler references the lane helper only inside the approved gated block,
- disabled gate preserves pass-through behavior,
- no duplicate helper calls exist,
- `score_worker_for_job` remains unchanged unless explicitly approved,
- no live model calls exist,
- no CT101 mutation exists,
- no job 23 mutation exists,
- no warmup execution enablement exists,
- no router activation exists,
- no raw prompt/message/body exposure exists,
- no secret exposure exists.

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-H: disabled scheduler pre-filter skeleton.

Phase 14J-H may add runtime code only if it remains default-off and proves no behavior change while disabled.
