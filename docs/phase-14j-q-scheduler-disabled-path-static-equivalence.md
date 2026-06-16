# Phase 14J-Q Scheduler Disabled-path Static Equivalence

Phase 14J-Q is a docs/smoke-only verification phase for scheduler disabled-path equivalence after the lane filter runtime call exists.

## Scope

This phase verifies disabled-path equivalence.

This phase does not change scheduler behavior.

This phase does not change runtime code.

This phase does not enable persistent lane workers.

This phase does not change service environment variables.

This phase does not call controller endpoints.

This phase does not call live model endpoints.

This phase does not query or mutate the database.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not change worker scoring.

This phase does not change worker assignment.

This phase does not change worker registration.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Runtime Shape

The scheduler has one lane gate call:

- `_phase14j_lane_workers_enabled()`

The scheduler has one lane filter call:

- `_phase14j_filter_workers_for_lane(workers, job)`

The filter call is guarded by:

- `phase14j_lane_scheduler_gate_enabled`

The filter call is ordered after:

- `workers = [worker_row_to_dict(row) for row in rows]`

The filter call is ordered before:

- `candidates = []`

Scoring still uses:

- `score_worker_for_job(worker, requirements)`


## Post-14J-N Gate Shape Clarification

After Phase 14J-N, `select_best_worker_for_job` may contain two `if phase14j_lane_scheduler_gate_enabled:` blocks:

- the Phase 14J-H no-op scheduler gate skeleton,
- the Phase 14J-N filter-call gate block.

The required invariant is exactly one filter-containing gate block.

## Disabled-path Equivalence Requirement

When `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is unset or disabled:

- the scheduler gate evaluates false,
- the scheduler does not execute the filter call,
- the helper still returns the original workers list when called directly,
- `workers` remains equivalent to the pre-14J-N worker list,
- scoring remains unchanged,
- assignment remains unchanged,
- fallback remains unchanged,
- worker registration remains unchanged.

## Verification Boundary

This phase uses static AST/source checks and isolated helper checks only.

This phase does not import the controller app.

This phase does not start services.

This phase does not contact CT101.

This phase does not call network endpoints.

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-R: runtime enablement readiness checkpoint.

Phase 14J-R should still be docs/smoke-only unless explicitly approved otherwise.
