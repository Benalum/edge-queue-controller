# Laptop Queue Idempotent Completion — Stage 5E-17

## Purpose

Stage 5E-17 adds duplicate completion safety for laptop-owned queue jobs.

This protects against worker retries, network failures, and late worker responses after recovery.

## Behavior added

The laptop queue completion helper now supports:

- running job assigned to the same worker can transition to complete
- running job assigned to the same worker can transition to failed
- duplicate success for an already complete job returns the current job row without mutation
- duplicate failure for an already failed job returns the current job row without mutation
- late success after failure or recovery is refused
- late failure after success is refused
- wrong worker completion is refused
- queued job completion is refused

## Why this matters

Once CT101 has a persistent laptop queue worker, duplicate completion can happen when:

- worker sends result but response is lost
- worker retries after a timeout
- recovery marks a job failed while the old worker later reports success
- wrong worker attempts to complete another worker's job

The queue must not overwrite final job state incorrectly.

## Smoke behavior

The smoke verifies:

1. synthetic job is claimed
2. first success completion works
3. duplicate success completion returns the original complete row
4. duplicate success does not overwrite result_json
5. late failure after success is rejected
6. second synthetic job is claimed
7. stale worker recovery fails the second job
8. late success after recovered failure is rejected
9. duplicate failure after recovered failure is accepted without mutation
10. synthetic cleanup removes all rows

## What this stage does not do

This stage does not:

- add retry fields
- add lease fields
- requeue jobs
- start persistent CT101 workers
- change Docker Compose
- migrate production jobs
- change chat/study behavior

## Next stage

Stage 5E-18 can plan a dormant synthetic polling loop.

Persistent polling should still remain disabled by default and synthetic-only until production migration is explicitly planned.
