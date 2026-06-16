# Phase 14J-M Disabled Lane Filter Runtime Patch Contract

Phase 14J-M is a docs/smoke-only contract phase before adding the disabled lane filter runtime call.

## Scope

This phase records the exact runtime patch contract.

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

## Current Confirmed Candidate Variable

The selected candidate list variable for the future filter call is:

- `workers`

The source rows variable is:

- `rows`

The scored output variable remains:

- `candidates`

## Future Patch Boundary

The future runtime patch must insert after:

- `workers = [worker_row_to_dict(row) for row in rows]`

The future runtime patch must insert before:

- `candidates = []`

The future runtime patch may call:

- `_phase14j_filter_workers_for_lane(workers, job)`

Only when:

- `phase14j_lane_scheduler_gate_enabled` is true.

## Disabled Behavior Requirement

When `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` is disabled:

- `workers` must remain unchanged,
- `score_worker_for_job` must remain unchanged,
- assignment must remain unchanged,
- fallback must remain unchanged,
- worker registration must remain unchanged,
- browser/API output shape must remain unchanged.

## Candidate Next Phase

After this contract, the next safe phase can be Phase 14J-N: disabled lane filter runtime call skeleton.
