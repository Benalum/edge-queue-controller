# Phase 14J-AD Apply-wrapper Static Validation and Pre-apply Checkpoint

Phase 14J-AD is a docs/smoke-only static validation and pre-apply checkpoint for the default-off worker registry lane metadata apply wrapper.

## Scope

This phase records the pre-apply checkpoint.

This phase statically validates the wrapper artifact.

This phase does not execute the apply wrapper.

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

## Source Artifacts

This checkpoint validates:

- `ops/db/apply-default-off-worker-registry-lane-metadata.sh`
- `ops/db/default-off-worker-registry-lane-metadata.sql`

## Pre-apply Decision

Schema apply remains blocked until a later explicitly approved apply phase.

Do not run:

- `ops/db/apply-default-off-worker-registry-lane-metadata.sh APPLY_DEFAULT_OFF_WORKER_LANE_METADATA`

Do not set:

- `EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1`

## Candidate Next Phase

After this phase, the next safe phase can be Phase 14J-AE: guarded pre-apply DB path and backup readiness inspection, read-only.
