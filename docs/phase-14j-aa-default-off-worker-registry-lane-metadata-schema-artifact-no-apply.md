# Phase 14J-AA Default-off Worker Registry Lane Metadata Schema Artifact, No Apply

Phase 14J-AA creates a no-apply SQL schema artifact for future default-off worker registry lane metadata support.

## Scope

This phase creates a schema artifact.

This phase does not apply the schema artifact.

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

## SQL Artifact

This phase writes:

- `ops/db/default-off-worker-registry-lane-metadata.sql`

The SQL artifact targets:

- SQLite DB: `edge_queue.sqlite3`
- Table: `workers`

## Additive Columns

The artifact contains additive column statements for:

- `worker_role TEXT DEFAULT 'primary'`
- `worker_lane TEXT DEFAULT ''`
- `accepts_lane_jobs INTEGER DEFAULT 0`
- `capabilities TEXT DEFAULT '[]'`
- `disabled INTEGER DEFAULT 0`
- `current_running_jobs INTEGER DEFAULT 0`
- `state TEXT DEFAULT 'available'`
- `computed_health TEXT DEFAULT ''`

## No-apply Boundary

The artifact must not be applied directly in this phase.

A future apply wrapper must inspect existing columns first and apply only missing columns.

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-AB: default-off worker registry lane metadata apply-wrapper plan, docs/smoke only.
