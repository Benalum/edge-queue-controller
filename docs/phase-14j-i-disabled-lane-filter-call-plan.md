# Phase 14J-I Disabled Lane Filter Call Plan

Phase 14J-I is a docs/smoke-only plan for the future disabled lane filter call inside scheduler selection.

## Scope

This phase plans the future lane filter call.

This phase does not change scheduler behavior.

This phase does not call the lane worker filter helper.

This phase does not filter the primary worker.

This phase does not change worker scoring.

This phase does not change worker assignment.

This phase does not change worker registration.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Checkpoint

Latest completed checkpoint before this phase:

- Phase 14J-H added a disabled scheduler gate skeleton inside `select_best_worker_for_job`.
- Phase 14J-G planned disabled scheduler integration.
- Phase 14J-F audited scheduler integration readiness.
- Phase 14J-E added default-off persistent lane worker helper skeletons.

## Current Runtime State

`select_best_worker_for_job` currently has exactly one scheduler lane gate call:

- `_phase14j_lane_workers_enabled()`

It does not call:

- `_phase14j_filter_workers_for_lane(...)`
- `_phase14j_worker_eligible_for_job(...)`
- `_phase14j_job_lane_metadata(...)`
- `_phase14j_worker_lane_metadata(...)`

## Future Filter Call Shape

A later runtime phase may add a lane filter call inside the existing Phase 14J-H gated block.

The future shape should be:

1. Build the existing candidate worker list exactly as before.
2. Check `_phase14j_lane_workers_enabled()`.
3. If disabled, preserve the exact existing candidate worker list.
4. If enabled, call `_phase14j_filter_workers_for_lane(...)` only on bounded worker/job metadata.
5. If filtering produces no candidates, preserve fallback behavior unless a later fallback phase explicitly changes it.
6. Continue existing scoring with `score_worker_for_job`.

## No-Behavior-Change Rule

When `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is disabled:

- candidate workers must remain unchanged,
- scoring must remain unchanged,
- assignment must remain unchanged,
- fallback behavior must remain unchanged,
- queue behavior must remain unchanged,
- browser/API output must remain unchanged,
- worker registration must remain unchanged.

## Primary Worker Boundary

Primary/default worker filtering remains separate.

This phase does not filter the primary worker.

The future first filter-call phase should not permanently block the primary worker unless a later primary-filtering phase explicitly approves it.

## Required Future Smoke Proofs

The future runtime filter-call phase must prove:

- exactly one lane gate call exists in `select_best_worker_for_job`,
- exactly one lane filter call exists inside the approved gated block,
- the filter call is skipped when the gate is disabled,
- `score_worker_for_job` remains free of lane helper calls,
- no CT101 mutation exists,
- no live model calls exist,
- no job 23 mutation exists,
- no warmup execution enablement exists,
- no router activation exists,
- no raw prompt/message/body exposure exists,
- no secret exposure exists.

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-J: disabled lane filter call skeleton.

Phase 14J-J may add runtime code only if it proves disabled gate behavior remains pass-through.
