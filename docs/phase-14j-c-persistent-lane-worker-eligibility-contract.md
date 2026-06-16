# Phase 14J-C Persistent Lane Worker Eligibility Contract

Phase 14J-C is a docs/smoke-only contract design phase for persistent lane worker metadata and eligibility.

## Scope

This phase designs the future lane metadata and worker eligibility contract.

This phase does not implement persistent lane workers.

This phase does not add runtime helper code.

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

- Phase 14J-B inspected persistent lane worker implementation surfaces.
- Router evidence work remains parked after Phase 14I-AZ.
- Router shadow evidence writer remains absent.
- Runtime router evidence persistence remains absent.
- Router activation remains parked.

## Design Goal

The future lane worker system needs a small, explicit eligibility contract before any scheduler behavior changes.

The goal is to answer one question safely:

Can this worker accept this job right now?

The answer must be based only on bounded metadata and safe worker state.

## Future Job Metadata Contract

A future job may need bounded lane metadata such as:

- `job_lane`
- `required_capabilities`
- `preferred_worker_role`
- `allow_primary_fallback`
- `allow_legacy_fallback`
- `requires_lane_worker`
- `estimated_vram_mb`
- `estimated_ram_mb`
- `estimated_duration_class`
- `priority_class`

Default behavior must preserve current live behavior when lane mode is disabled.

## Future Worker Metadata Contract

A future worker may need bounded lane metadata such as:

- `worker_id`
- `worker_role`
- `worker_lane`
- `worker_pool`
- `capabilities`
- `max_concurrent_jobs`
- `current_running_jobs`
- `supports_primary_fallback`
- `accepts_lane_jobs`
- `disabled`
- `stale`
- `unhealthy`
- `offline`

## Future Eligibility Result Contract

A future eligibility helper should return a small structured result.

Candidate fields:

- `eligible`
- `reason_code`
- `worker_id`
- `job_lane`
- `worker_lane`
- `matched_capabilities`
- `missing_capabilities`
- `fallback_used`
- `blocked_by_state`
- `gate_enabled`

The result must not contain raw prompts, raw messages, request bodies, queue payloads, full job payloads, secrets, cookies, auth headers, bearer tokens, or unbounded user content.

## Candidate Future Helper Names

A later implementation phase may define helpers such as:

- `_phase14j_lane_workers_enabled()`
- `_phase14j_job_lane_metadata(...)`
- `_phase14j_worker_lane_metadata(...)`
- `_phase14j_worker_eligible_for_job(...)`
- `_phase14j_filter_workers_for_lane(...)`

These names are design notes only in this phase and must not exist in runtime code yet.

## Candidate Future Environment Gate

A later implementation phase may define a default-off gate:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`

Disabled behavior:

- unset = disabled,
- empty = disabled,
- `0` = disabled,
- `false` = disabled.

Only explicit approved truthy values may enable lane-aware behavior in a later gated phase.

## Future Eligibility Rules

A future worker eligibility helper should reject a worker when:

- worker is disabled,
- worker is stale,
- worker is unhealthy,
- worker is offline,
- required capabilities are missing,
- job requires a lane worker and worker is not in that lane,
- primary fallback is not allowed,
- legacy fallback is not allowed,
- worker has reached concurrency capacity.

A future helper may accept a worker when:

- worker is available,
- worker has required capabilities,
- worker lane matches the job lane,
- fallback is explicitly allowed,
- concurrency capacity is available.

## Future Primary Worker Filtering Rule

The future primary/default worker must not take protected lane jobs unless the job explicitly allows primary fallback.

This preserves a safe separation between:

- default/general work,
- study work,
- companion work,
- warmup-related work,
- future image/voice/deep reasoning work,
- protected specialized lanes.

## No-Behavior-Change Requirement

When the future lane gate is disabled:

- existing scheduler behavior must remain unchanged,
- existing fallback behavior must remain unchanged,
- existing worker registration behavior must remain unchanged,
- existing queue/job creation behavior must remain unchanged,
- existing browser/API response behavior must remain unchanged.

## Required Later Validation

Before runtime implementation, a later phase must provide static smokes for:

- default-off gate,
- helper marker presence,
- disabled behavior unchanged,
- no live model calls,
- no CT101 mutation,
- no job 23 mutation,
- no secret exposure,
- no raw prompt/message exposure,
- no router activation,
- no warmup execution enablement.

Live validation must remain separately approved and gated.

## Next Safe Step

After this phase, the next safe step should be Phase 14J-D: default-off helper implementation plan or static helper skeleton plan.

Runtime helper code should still wait until explicitly approved.
