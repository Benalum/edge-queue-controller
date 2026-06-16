# Phase 14J-D Persistent Lane Worker Default-Off Helper Plan

Phase 14J-D is a docs/smoke-only implementation plan for future default-off persistent lane worker helper code.

## Scope

This phase plans the helper implementation boundary.

This phase does not add runtime helper code.

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

- Phase 14J-C defined the persistent lane worker eligibility contract.
- Phase 14J-B inspected persistent lane worker implementation surfaces.
- Phase 14J-A reopened persistent lane worker blocker re-entry.
- Router evidence work remains parked after Phase 14I-AZ.

## Future Default-Off Gate

A future implementation phase may add this gate:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`

Required disabled values:

- unset,
- empty,
- `0`,
- `false`,
- `False`,
- `FALSE`,
- `no`,
- `off`.

Only explicit approved truthy values should enable lane-aware behavior in a later gated phase.

## Future Helper Set

A future implementation phase may add small helpers such as:

- `_phase14j_lane_workers_enabled()`
- `_phase14j_job_lane_metadata(job)`
- `_phase14j_worker_lane_metadata(worker)`
- `_phase14j_worker_eligible_for_job(worker, job)`
- `_phase14j_filter_workers_for_lane(workers, job)`

These helpers are not added in this phase.

## Future Helper Responsibilities

### Gate Helper

`_phase14j_lane_workers_enabled()` should:

- read only the explicit environment gate,
- default to disabled,
- treat unknown values as disabled,
- return a boolean,
- not call the database,
- not call models,
- not mutate scheduler state.

### Job Metadata Helper

`_phase14j_job_lane_metadata(job)` should:

- derive bounded lane metadata from existing job fields,
- tolerate missing fields,
- preserve existing behavior when lane mode is disabled,
- avoid raw prompt/message/body extraction,
- avoid full payload persistence or logging.

### Worker Metadata Helper

`_phase14j_worker_lane_metadata(worker)` should:

- derive bounded worker metadata from existing registry fields,
- include safe state fields such as disabled, stale, unhealthy, and offline,
- include capabilities only as bounded labels,
- avoid secrets or raw worker payload dumps.

### Eligibility Helper

`_phase14j_worker_eligible_for_job(worker, job)` should:

- reject disabled workers,
- reject stale workers,
- reject unhealthy workers,
- reject offline workers,
- reject workers missing required capabilities,
- reject primary/default fallback unless explicitly allowed,
- return a bounded structured result.

### Filter Helper

`_phase14j_filter_workers_for_lane(workers, job)` should:

- call the eligibility helper,
- return the eligible workers and bounded rejection reasons,
- preserve original ordering unless a later scoring phase changes it,
- avoid changing scheduler behavior while the gate is disabled.

## No-Behavior-Change Requirement

When the future gate is disabled:

- existing scheduler behavior must remain unchanged,
- existing worker scoring must remain unchanged,
- existing worker assignment must remain unchanged,
- existing fallback behavior must remain unchanged,
- existing queue behavior must remain unchanged,
- existing browser/API output must remain unchanged.

## Runtime Integration Boundary

A future implementation phase should add helpers first without wiring them into live scheduler behavior.

Scheduler integration must be a later separate gate.

Primary worker filtering must be a later separate gate.

Live validation must be a later separate gate.

## Future Static Smoke Requirements

The future helper implementation phase must include static smokes for:

- helper marker presence,
- gate default-off behavior,
- unknown gate values disabled,
- future helper output boundedness,
- no live model calls,
- no CT101 mutation,
- no job 23 mutation,
- no secret exposure,
- no raw prompt/message/body exposure,
- no router activation,
- no warmup execution enablement,
- no live scheduler behavior change while disabled.

## Safety Boundaries

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
- enable persistent lane workers without explicit approval.

## Next Safe Step

After this phase, the next safe step can be Phase 14J-E: add default-off helper skeletons with no scheduler integration.

Phase 14J-E must still keep lane behavior disabled by default and must prove no behavior change while disabled.
