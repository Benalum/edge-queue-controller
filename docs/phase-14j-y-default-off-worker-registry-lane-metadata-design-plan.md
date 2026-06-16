# Phase 14J-Y Default-off Worker Registry Lane Metadata Design Plan

Phase 14J-Y is a docs/smoke-only design plan for default-off worker registry lane metadata support.

## Scope

This phase records the default-off metadata design.

This phase does not query or mutate the database.

This phase does not change the database schema.

This phase does not change scheduler behavior.

This phase does not change runtime code.

This phase does not enable persistent lane workers.

This phase does not change service environment variables.

This phase does not restart or reload services.

This phase does not call controller endpoints.

This phase does not call live model endpoints.

This phase does not mutate CT101.

This phase does not mutate job 23.

This phase does not change worker scoring.

This phase does not change worker assignment.

This phase does not change worker registration.

This phase does not enable warmup execution.

This phase does not enable router model selection.

This phase does not enable router evidence writer persistence.

## Source Decision

Phase 14J-X recorded that persistent lane worker enablement is blocked because the worker registry lane metadata columns are missing.

Phase 14J-W selected the `workers` table and found only these expected fields present:

- `worker_id`
- `name`
- `target_name`
- `max_concurrent_jobs`

## Candidate Metadata Design

Future default-off metadata support may add or derive:

- `worker_role`
- `worker_lane`
- `accepts_lane_jobs`
- `capabilities`
- `current_running_jobs`
- `max_concurrent_jobs`
- `disabled`
- `state`
- `computed_health`

Existing workers must default safely:

- role defaults to `primary`,
- lane defaults to empty,
- lane acceptance defaults to false,
- capabilities default to empty or existing compatible behavior,
- persistent lane filtering remains disabled unless the service flag is explicitly enabled later.

## Activation Boundary

Adding metadata support must not activate persistent lane filtering.

The service flag remains separate:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED`

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-Z: default-off worker registry lane metadata schema patch contract, docs/smoke only.
