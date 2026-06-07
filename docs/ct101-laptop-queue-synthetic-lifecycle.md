# CT101 to Laptop Queue Synthetic Lifecycle — Stage 5E-8

## Purpose

Stage 5E-8 proves CT101 can perform a full synthetic job lifecycle against the laptop/controller queue API.

This stage uses synthetic data only.

## What this stage does

The smoke test:

1. Reads the laptop queue token from the laptop token file.
2. Ensures CT101 has the token file outside git.
3. Starts a temporary laptop Uvicorn server bound to 0.0.0.0.
4. Creates synthetic laptop queue rows through the laptop API.
5. From CT101, claims the first synthetic job.
6. From CT101, completes the first synthetic job.
7. From CT101, claims the second synthetic job.
8. From CT101, fails the second synthetic job.
9. Cleans up all synthetic rows through the laptop API.

## Endpoint paths tested

- GET /internal/laptop-queue/summary
- POST /internal/laptop-queue/synthetic/setup
- POST /internal/laptop-queue/jobs/claim
- POST /internal/laptop-queue/jobs/{job_id}/complete
- POST /internal/laptop-queue/synthetic/cleanup

## What this stage does not do

This stage does not:

- modify CT101 worker code
- start a real CT101 worker loop
- migrate production jobs
- change public UI behavior
- change power automation
- remove CT101 job routes
- remove old queues

## Why this matters

Before wiring CT101 workers into laptop-owned queue processing, CT101 must prove it can safely claim and complete synthetic jobs against the laptop queue API.

This test verifies the cross-machine request path without touching production jobs.

## Cleanup rule

The smoke must delete all synthetic rows.

If cleanup leaves synthetic rows behind, the smoke fails.

## Next stage

Stage 5E-9 can inspect the CT101 worker code and plan the smallest synthetic-only worker mode.

Production job migration should still wait until worker integration is proven with synthetic jobs.
