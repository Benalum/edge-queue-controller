# Phase 14J-K Lane Filter Candidate Variable Map

Phase 14J-K is a docs/smoke-only mapping phase before adding a runtime lane filter call.

## Scope

This phase maps candidate variables inside `select_best_worker_for_job`.

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

- Phase 14J-J inspected the exact insertion point.
- Phase 14J-I planned the disabled lane filter call.
- Phase 14J-H added the disabled scheduler gate skeleton.
- Phase 14J-E added default-off persistent lane worker helpers.

## Mapping Artifact

This phase records a bounded variable map in:

- `docs/phase-14j-k-lane-filter-candidate-variable-map-select-best-worker-variable-map.txt`

The map includes:

- assignment targets,
- loop targets,
- call names,
- candidate-looking variable names,
- current gate and filter-call status.

## Current Required Shape

`select_best_worker_for_job` must still have:

- exactly one `_phase14j_lane_workers_enabled()` call,
- no `_phase14j_filter_workers_for_lane(...)` call,
- no `_phase14j_worker_eligible_for_job(...)` call,
- no metadata helper calls,
- unchanged `score_worker_for_job` usage.

## Future Runtime Phase

The future runtime filter-call phase must use this map to choose the exact insertion point.

The future phase must preserve disabled behavior:

- disabled gate means pass-through,
- worker scoring remains unchanged,
- worker assignment remains unchanged,
- fallback behavior remains unchanged,
- primary/default worker filtering remains separate,
- no CT101 mutation,
- no live model calls.

## Candidate Next Phase

After this mapping phase, the next safe phase can be Phase 14J-L: disabled lane filter no-op candidate snapshot or disabled filter call skeleton.
