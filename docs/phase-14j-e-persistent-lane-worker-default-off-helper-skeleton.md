# Phase 14J-E Persistent Lane Worker Default-Off Helper Skeleton

Phase 14J-E adds default-off persistent lane worker helper skeletons without scheduler integration.

## Scope

This phase adds helper code only.

This phase does not enable persistent lane workers.

This phase does not change worker registration.

This phase does not change scheduler behavior.

This phase does not filter the primary worker.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not enable warmup execution.

This phase does not enable router model selection.

## Current Checkpoint

Latest completed checkpoint before this phase:

- Phase 14J-D planned persistent lane worker default-off helpers.
- Phase 14J-C defined the persistent lane worker eligibility contract.
- Phase 14J-B inspected persistent lane worker implementation surfaces.
- Phase 14J-A reopened persistent lane worker blocker re-entry.
- Router evidence remains parked after Phase 14I-AZ.

## Runtime Change

This phase adds default-off helper skeletons to `edge_controller.py`.

The helpers are intentionally not wired into:

- `select_best_worker_for_job`,
- `score_worker_for_job`,
- `worker_heartbeat`,
- `workers_registry`,
- `scheduler_preview`,
- public routes,
- queued chat routes,
- job creation routes.

## Added Helper Gate

This phase adds:

- `_phase14j_lane_workers_enabled()`

The helper reads:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`

Disabled values:

- unset,
- empty,
- `0`,
- `false`,
- `False`,
- `FALSE`,
- `no`,
- `off`,
- unknown values.

Truthy values:

- `1`,
- `true`,
- `yes`,
- `on`.

Even when truthy, no scheduler behavior changes in this phase because the helpers are not integrated.

## Added Metadata Helpers

This phase adds bounded metadata helpers:

- `_phase14j_job_lane_metadata(job)`
- `_phase14j_worker_lane_metadata(worker)`

These helpers return bounded metadata only.

They must not return raw prompts, raw messages, raw request bodies, raw queue payloads, full job payloads, secrets, cookies, auth headers, bearer tokens, or unbounded user content.

## Added Eligibility Helpers

This phase adds helper skeletons:

- `_phase14j_worker_eligible_for_job(worker, job)`
- `_phase14j_filter_workers_for_lane(workers, job)`

These helpers are not called by scheduler code in this phase.

When the gate is disabled, the eligibility helper returns a pass-through safe result so disabled behavior remains non-filtering.

When the gate is disabled, the filter helper returns the original worker list.

## No-Behavior-Change Requirement

The smoke for this phase proves:

- helper markers exist,
- helper gate is disabled by default,
- unknown gate values remain disabled,
- helper outputs are bounded,
- helper code compiles,
- scheduler functions are not wired to the new helpers,
- previous router evidence writer remains absent,
- disabled warmup markers remain present.

## Prior Smoke Compatibility

Earlier 14J-B, 14J-C, and 14J-D smokes were written before runtime helper skeletons existed. This phase updates those smokes so they remain valid after the helper skeleton phase while continuing to protect against router writer activation and unintended live behavior.

## Still Not Done

This phase does not complete persistent lane workers.

Still future work:

- scheduler integration,
- primary/default worker filtering,
- live lane-aware assignment,
- live validation,
- fallback behavior changes,
- worker registration changes,
- CT101 changes.
