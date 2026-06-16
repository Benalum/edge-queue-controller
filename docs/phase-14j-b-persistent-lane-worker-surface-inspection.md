# Phase 14J-B Persistent Lane Worker Surface Inspection

Phase 14J-B is a docs/smoke-only implementation surface inspection for persistent lane workers and primary worker filtering.

## Scope

This phase inspects where future persistent lane worker behavior should fit.

This phase does not implement persistent lane workers.

This phase does not change worker registration.

This phase does not change scheduler behavior.

This phase does not filter the primary worker yet.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Checkpoint

Latest completed checkpoint before this phase:

- Phase 14J-A persistent lane worker re-entry baseline.
- Router evidence work is parked after Phase 14I-AZ.
- Router shadow evidence schema exists and is applied.
- Router evidence writer remains absent.
- Runtime router evidence persistence remains absent.
- Router activation remains parked.

## Active Blockers Under Inspection

This phase inspects the surfaces related to:

- `persistent_lane_workers_not_active`
- `primary_worker_unfiltered`
- `worker_assignment_not_lane_safe`
- `scheduler_lane_awareness_not_proven`
- `fallback_lane_behavior_not_proven`
- `warmup_execution_disabled`
- `ct101_runtime_protected`

## Implementation Surface Categories

Future persistent lane worker work should inspect these controller-owned surfaces:

1. Worker registration surface
2. Worker heartbeat and status surface
3. Worker capability metadata surface
4. Queue job creation surface
5. Scheduler job selection surface
6. Worker assignment and dispatch surface
7. Fallback behavior surface
8. Disabled/stale/unhealthy/offline worker handling surface
9. Primary/default worker filtering surface
10. Future lane/pool label surface

## Future Lane Concepts

A later implementation may need bounded concepts such as:

- lane name,
- worker pool,
- worker role,
- worker capability set,
- primary/default worker flag,
- lane-specific eligibility,
- fallback eligibility,
- disabled/stale/unhealthy/offline exclusion.

These concepts must be introduced slowly and must not change live routing until gated.

## Future Filtering Goal

The future primary worker filtering goal is to prevent the default worker from accidentally accepting jobs that belong to a protected or specialized lane.

A future filter should answer:

- Is this worker eligible for this job?
- Is this worker stale, disabled, unhealthy, or offline?
- Does this job require a lane-specific worker?
- Is fallback allowed for this job?
- Is primary/default fallback safe for this job?

## Future No-Behavior-Change Order

The safest implementation order is:

1. Inspect surfaces.
2. Design lane metadata contract.
3. Add default-off helper names and static smokes.
4. Add disabled-by-default eligibility helper.
5. Verify default behavior unchanged.
6. Add scheduler integration behind a default-off flag.
7. Verify no live behavior change while disabled.
8. Add explicit gated validation only after smokes prove safety.

## Required Safety Boundaries

Future implementation phases must not:

- mutate CT101 unless explicitly approved,
- call live model endpoints unless explicitly approved,
- mutate job 23,
- expose secrets,
- expose raw prompts,
- expose raw messages,
- expose raw request bodies,
- expose raw queue summaries,
- expose full job payloads,
- remove legacy fallback yet,
- gate backend direct `/jobs` yet,
- remove Study UI `requested_model` yet,
- enable router model selection yet,
- enable warmup execution yet,
- enable persistent lane workers without a default-off gate.

## Candidate Future Environment Gate

A future implementation phase may define a default-off gate such as:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`

Required disabled behavior:

- unset = disabled,
- empty = disabled,
- `0` = disabled,
- `false` = disabled,
- only explicit approved truthy values may enable lane-aware behavior.

## Decision After This Phase

After Phase 14J-B, the next safe step should be either:

- Phase 14J-C lane metadata and eligibility contract design, docs/smoke only, or
- a narrow default-off helper implementation phase if the inspected surfaces are clear enough.

No runtime lane behavior should change until a separate implementation phase is explicitly approved.
