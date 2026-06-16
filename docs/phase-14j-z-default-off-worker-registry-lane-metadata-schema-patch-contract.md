# Phase 14J-Z Default-off Worker Registry Lane Metadata Schema Patch Contract

Phase 14J-Z is a docs/smoke-only schema patch contract for future default-off worker registry lane metadata support.

## Scope

This phase records the future schema patch contract.

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

Phase 14J-X blocked persistent lane worker enablement because worker registry lane metadata was missing.

Phase 14J-Y designed default-off worker registry lane metadata support.

## Future Target

The future schema patch target is:

- SQLite DB: `edge_queue.sqlite3`
- Table: `workers`

## Future Additive Columns

The future patch may add:

- `worker_role TEXT DEFAULT 'primary'`
- `worker_lane TEXT DEFAULT ''`
- `accepts_lane_jobs INTEGER DEFAULT 0`
- `capabilities TEXT DEFAULT '[]'`
- `disabled INTEGER DEFAULT 0`
- `current_running_jobs INTEGER DEFAULT 0`
- `state TEXT DEFAULT 'available'`
- `computed_health TEXT DEFAULT ''`

## Activation Boundary

The schema patch alone must not activate persistent lane workers.

Do not set:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1`

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-AA: default-off worker registry lane metadata schema artifact, docs/smoke only, no apply.
