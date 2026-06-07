# Synthetic Laptop Job Lifecycle Smoke — Stage 5E-2

## Purpose

Stage 5E-2 adds an isolated synthetic job lifecycle smoke for the laptop/controller Postgres queue foundation.

This stage proves that the laptop-owned queue tables can support basic lifecycle behavior before CT101 workers are connected.

## What the smoke does

The smoke creates synthetic rows only:

- app_users
- app_worker_nodes
- app_workers
- app_jobs

It then verifies:

- queued job creation
- queued to running claim simulation
- worker busy state
- running to complete transition
- result_json storage
- queued to running failure simulation
- running to failed transition
- error_text storage
- worker returns to idle
- cleanup leaves no synthetic rows behind

## What this stage does not do

This stage does not:

- expose new API routes
- connect CT101 workers
- migrate production jobs
- change controller runtime behavior
- change user-facing behavior
- change power automation
- create production data

## Why this comes before worker integration

Before CT101 workers claim laptop-owned jobs, the laptop queue tables must prove they can safely represent:

- queued
- running
- complete
- failed

This keeps the next stage smaller and safer.

## Cleanup requirement

The smoke must delete only rows with its synthetic IDs.

If cleanup leaves any synthetic rows behind, the smoke fails.

## Next stage

Stage 5E-3 should add helper functions or an internal controller queue API for synthetic laptop jobs.

CT101 worker integration should still wait until the laptop queue facade is tested locally.
