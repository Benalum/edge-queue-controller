# Phase 14J-AB Default-off Worker Registry Lane Metadata Apply-wrapper Plan

Phase 14J-AB is a docs/smoke-only plan for a future guarded apply wrapper.

## Scope

This phase records the apply-wrapper plan.

This phase does not create the apply wrapper.

This phase does not execute an apply wrapper.

This phase does not apply the SQL artifact.

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

## Source Artifact

The future apply wrapper will be based on:

- `ops/db/default-off-worker-registry-lane-metadata.sql`

## Future Wrapper Requirements

A future apply wrapper must:

- inspect existing columns first,
- apply only missing additive columns,
- create or require a backup/snapshot before mutation,
- keep `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` absent or disabled,
- avoid service restart/reload,
- avoid endpoint calls,
- avoid CT101 mutation,
- avoid job 23 mutation.

## Future Target Columns

The future wrapper may add:

- `worker_role TEXT DEFAULT 'primary'`
- `worker_lane TEXT DEFAULT ''`
- `accepts_lane_jobs INTEGER DEFAULT 0`
- `capabilities TEXT DEFAULT '[]'`
- `disabled INTEGER DEFAULT 0`
- `current_running_jobs INTEGER DEFAULT 0`
- `state TEXT DEFAULT 'available'`
- `computed_health TEXT DEFAULT ''`

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-AC: default-off worker registry lane metadata apply-wrapper artifact, no execution.
