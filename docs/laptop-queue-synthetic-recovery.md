# Laptop Queue Synthetic Recovery — Stage 5E-16

## Purpose

Stage 5E-16 adds a synthetic-safe laptop queue recovery endpoint.

The endpoint handles stale synthetic workers and stuck running synthetic jobs.

## Endpoint added

- POST /internal/laptop-queue/recover

## Current behavior

The recovery endpoint:

- requires X-Laptop-Queue-Token
- accepts stale_seconds
- accepts synthetic_prefixes
- only acts on synthetic worker IDs
- only acts on synthetic job IDs
- marks stale workers offline
- clears stale worker current_job_id
- marks stuck running jobs failed
- writes a clear recovery error_text

## Why jobs are failed, not requeued

The current app_jobs schema does not yet include:

- retry_count
- max_retries
- lease_expires_at
- idempotency_key

Because retry fields do not exist yet, Stage 5E-16 fails stuck running jobs instead of requeueing them.

Requeue behavior is postponed until retry semantics are explicitly designed.

## Smoke behavior

The smoke verifies:

1. temporary laptop API starts
2. synthetic worker registers
3. synthetic worker claims a job
4. synthetic worker heartbeats busy
5. synthetic worker and running job are made stale using synthetic-only test data
6. recovery endpoint is called
7. stale synthetic worker becomes offline
8. stuck synthetic running job becomes failed
9. cleanup removes all synthetic rows

## What this stage does not do

This stage does not:

- requeue jobs
- add retry fields
- add lease fields
- change schemas
- start persistent CT101 workers
- change Docker Compose
- migrate production jobs
- change chat/study behavior

## Next stage

Stage 5E-17 should plan or implement idempotent completion behavior before persistent polling is allowed.

Persistent CT101 worker polling should still wait until heartbeat, recovery, and duplicate completion behavior are proven.
