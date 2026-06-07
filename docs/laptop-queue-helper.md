# Laptop Queue Helper Module — Stage 5E-3

## Purpose

Stage 5E-3 adds a controller-side helper module for laptop-owned Postgres queue operations.

This is a bridge between raw SQL smoke tests and future internal controller queue API endpoints.

## Added module

Helper module:

- edge_modules/laptop_queue.py

Smoke check:

- ops/smoke/check-laptop-queue-helper.sh

## What the helper can do

The helper can:

- load the laptop Postgres env file outside git
- connect through psql without adding Python database dependencies
- create synthetic app_users rows
- create synthetic app_worker_nodes rows
- create synthetic app_workers rows
- create synthetic app_jobs rows
- claim a queued job
- complete a running job
- fail a running job
- inspect worker state
- cleanup synthetic rows

## What this stage does not do

This stage does not:

- expose API routes
- connect CT101 workers
- migrate production jobs
- change controller runtime behavior
- change user-facing behavior
- replace SQLite
- remove old queue code

## Why psql subprocess is used for now

The controller repo does not yet have a committed Python Postgres dependency.

Using psql keeps Stage 5E-3 additive and low-risk.

A later stage may introduce a proper Postgres driver after the queue facade API design is stable.

## Cleanup requirement

The helper smoke uses only synthetic IDs and must clean up all synthetic rows.

If cleanup leaves rows behind, the smoke fails.

## Next stage

Stage 5E-4 can add internal controller queue API endpoints using the helper.

CT101 worker integration should still wait until local internal endpoints pass synthetic claim/complete smoke tests.
