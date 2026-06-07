# Laptop Queue Internal API — Stage 5E-4

## Purpose

Stage 5E-4 adds internal-token-protected controller endpoints for the laptop-owned queue facade.

These endpoints are synthetic-only in this stage.

## Endpoints added

- GET /internal/laptop-queue/summary
- POST /internal/laptop-queue/synthetic/setup
- POST /internal/laptop-queue/jobs/claim
- POST /internal/laptop-queue/jobs/{job_id}/complete
- POST /internal/laptop-queue/synthetic/cleanup

## Token protection

Requests must include:

- X-Laptop-Queue-Token

The token is read from either:

- LAPTOP_QUEUE_INTERNAL_TOKEN environment variable
- ~/.config/ai-platform-controller/internal-queue.env

The token file must stay outside git.

## What this stage does

This stage proves the controller can expose laptop queue operations through API routes.

The smoke starts a temporary Uvicorn server on localhost and tests:

- summary endpoint
- synthetic setup
- claim first queued job
- complete success job
- claim second queued job
- fail second job
- synthetic cleanup

## What this stage does not do

This stage does not:

- connect CT101 workers
- expose user-facing queue UI
- migrate production jobs
- change production queue behavior
- change power automation
- remove old CT101 job routes
- remove old SQLite/controller tables

## Future cleanup requirement

After laptop queue migration is complete and verified, remove unused legacy queue pieces in a separate cleanup stage.

Cleanup must wait until:

- laptop queue is source of truth
- CT101 workers use laptop queue
- backups pass
- restore has been tested
- production behavior is verified
- rollback instructions exist
