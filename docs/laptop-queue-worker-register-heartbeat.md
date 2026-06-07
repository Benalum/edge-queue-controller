# Laptop Queue Worker Register and Heartbeat — Stage 5E-15

## Purpose

Stage 5E-15 adds internal laptop queue worker registration and heartbeat endpoints.

This stage is additive and synthetic-safe.

## Endpoints added

- POST /internal/laptop-queue/workers/register
- POST /internal/laptop-queue/workers/heartbeat

## Existing schema used

This stage uses existing tables only:

- app_workers
- app_worker_nodes
- app_jobs

No schema changes are made.

## Register behavior

The register endpoint:

- requires X-Laptop-Queue-Token
- creates or updates app_worker_nodes
- creates or updates app_workers
- updates last_heartbeat_at
- updates app_worker_nodes.last_seen_at
- returns server-side worker state

Registration is idempotent.

## Heartbeat behavior

The heartbeat endpoint:

- requires X-Laptop-Queue-Token
- requires worker_id
- updates app_workers.last_heartbeat_at
- updates app_workers.status
- updates app_workers.current_job_id
- optionally updates app_worker_nodes.last_seen_at
- returns server-side worker state

Heartbeat does not:

- claim jobs
- complete jobs
- fail jobs
- recover jobs
- create production jobs

## Smoke behavior

The smoke verifies:

1. temporary laptop API starts
2. synthetic jobs are created
3. synthetic worker registers
4. synthetic worker heartbeats idle
5. synthetic worker claims a job
6. synthetic worker heartbeats busy with the claimed job id
7. synthetic worker completes the job
8. synthetic worker heartbeats idle
9. cleanup removes all synthetic rows

## What this stage does not do

This stage does not:

- add recovery endpoint
- add stale worker handling
- add stuck job recovery
- change schemas
- change CT101 worker code
- start persistent CT101 workers
- change Docker Compose
- migrate production jobs
- change chat/study behavior

## Next stage

Stage 5E-16 should add laptop queue recovery planning or implementation for synthetic stale workers and stuck running jobs.

Persistent worker polling should still wait until recovery behavior is proven.
