# Laptop Queue Heartbeat and Recovery Plan — Stage 5E-14

## Purpose

Stage 5E-14 plans heartbeat, worker registration, stale worker handling, stuck running job recovery, and idempotent completion for the laptop-owned queue.

This stage is planning only.

No runtime behavior changes happen in this stage.

## Current proven foundation

Already proven:

- laptop Postgres app queue schema exists
- laptop internal queue API exists
- laptop queue token protection works
- CT101 can reach laptop queue API
- CT101 can claim/complete/fail synthetic laptop jobs
- CT101 one-shot worker smoke works
- CT101 dormant laptop queue client works
- CT101 dormant client one-shot smoke works

## Current gap

The laptop queue can support synthetic claim/complete/fail behavior, but persistent worker polling should not start yet.

Missing production-grade lifecycle pieces:

- worker registration endpoint
- worker heartbeat endpoint
- worker offline/stale detection
- running job lease or timeout behavior
- stuck running job recovery
- idempotent completion behavior
- duplicate completion handling
- worker shutdown reporting
- clear queue recovery command
- observability for laptop-owned worker state

## Inspection notes

Read-only inspection notes are saved at:

- docs/laptop-queue-heartbeat-recovery-inspection-notes.md

Primary files inspected:

- edge_controller.py
- edge_modules/laptop_queue.py
- ops/db/laptop-app-schema-v1.sql
- docs/laptop-job-queue-facade-plan.md
- docs/ct101-dormant-worker-path-plan.md
- docs/ct101-dormant-client-one-shot-smoke.md
- ops/smoke/check-laptop-queue-internal-api.sh
- ops/smoke/check-ct101-dormant-client-one-shot.sh

## Target future laptop queue endpoints

Future internal endpoints should include:

- POST /internal/laptop-queue/workers/register
- POST /internal/laptop-queue/workers/heartbeat
- POST /internal/laptop-queue/workers/offline
- POST /internal/laptop-queue/recover
- GET /internal/laptop-queue/summary

Existing Stage 5E endpoint paths should remain additive and backward compatible during testing.

## Worker registration behavior

A future worker registration endpoint should:

- require X-Laptop-Queue-Token
- accept worker id, name, node id, capabilities, and idle shutdown seconds
- create or update app_workers
- create or update app_worker_nodes if needed
- mark worker status idle unless it already has a running job
- update last_heartbeat_at
- return the registered worker state

Registration must be idempotent.

## Heartbeat behavior

A future heartbeat endpoint should:

- require X-Laptop-Queue-Token
- require worker id
- optionally include current job id
- update app_workers.last_heartbeat_at
- update app_workers.status
- update app_workers.current_job_id
- update app_worker_nodes.last_seen_at when a worker node is supplied
- return server-side view of worker state

Heartbeat must not create production jobs.

Heartbeat must not complete jobs.

## Stale worker behavior

A worker should be considered stale when:

- last_heartbeat_at is older than a configured threshold
- worker status is busy or idle but no recent heartbeat exists

Suggested default planning value:

- 120 seconds stale threshold for smoke tests
- later configurable in production

When a worker is stale:

- app_workers.status should become offline
- app_workers.current_job_id should be cleared after recovery decision
- related running jobs should either fail or return to queued based on retry policy

Because retry fields do not exist yet, the first implementation should likely fail stale running jobs with a clear error_text.

## Stuck running job recovery

A job should be considered stuck when:

- status is running
- assigned_worker_id points to a stale worker
- started_at or updated_at is older than a configured threshold

Initial safe behavior without schema changes:

- mark stuck running jobs as failed
- set error_text to a recovery message
- set finished_at
- set updated_at
- mark stale worker offline
- clear worker current_job_id

Do not requeue jobs until retry_count and max_retries exist.

## Idempotent completion behavior

Completion should be safe if:

- worker retries complete after network failure
- worker submits duplicate complete
- recovery already marked the job failed
- wrong worker tries to complete a job

Recommended behavior:

- completing running job assigned to the same worker succeeds
- completing already complete job with matching result can return current job without mutation
- completing already failed job should not overwrite failure unless explicitly allowed later
- completing job assigned to another worker should return an error
- completing queued job should return an error
- duplicate completion should not create duplicate assistant messages in later chat migration

## Schema gap

Current schema has:

- app_jobs.status
- app_jobs.assigned_worker_id
- app_jobs.started_at
- app_jobs.finished_at
- app_jobs.updated_at
- app_workers.status
- app_workers.current_job_id
- app_workers.last_heartbeat_at

Future schema fields may be useful later:

- app_jobs.lease_expires_at
- app_jobs.retry_count
- app_jobs.max_retries
- app_jobs.cancelled_at
- app_jobs.cancellation_reason
- app_jobs.idempotency_key
- app_workers.last_error
- app_workers.shutdown_requested_at

Do not add these fields in Stage 5E-14.

## Recommended Stage 5E-15 scope

Keep Stage 5E-15 small.

Recommended implementation:

- add laptop queue worker register endpoint
- add laptop queue worker heartbeat endpoint
- add synthetic smoke for register and heartbeat
- no persistent CT101 worker
- no production jobs
- no schema changes unless absolutely required

The smoke should:

1. start temporary laptop queue API
2. register synthetic worker
3. heartbeat synthetic worker idle
4. create synthetic job
5. claim synthetic job
6. heartbeat synthetic worker busy with job id
7. complete synthetic job
8. heartbeat synthetic worker idle
9. cleanup synthetic rows

## Recommended Stage 5E-16 scope

After register/heartbeat works:

- add laptop queue recovery endpoint
- add synthetic stale worker smoke
- add synthetic stuck running job smoke
- verify stale worker becomes offline
- verify stuck running job becomes failed
- verify cleanup passes

## What must be postponed

Postpone:

- persistent CT101 worker polling
- Docker Compose changes
- production chat migration
- production study migration
- retry/requeue behavior
- schema fields for retries or leases
- cleanup of old CT101 queue
- removal of old websites/pages/routes

## Rollback plan

Because Stage 5E-14 is documentation only:

- revert the controller commit
- no CT101 rollback needed
- no database rollback needed
- no service restart needed

For later implementation stages:

- keep changes additive
- keep CT101 production worker loop unchanged
- keep laptop queue behavior behind internal endpoints and tokens
- preserve current CT101 queue until production migration is proven
- run backup smoke before any schema change

## Cleanup requirement

After full migration is complete and verified, remove unused legacy pieces in a separate cleanup stage.

Cleanup candidates:

- old CT101 queue routes
- CT101 local jobs table usage
- old one-shot smoke helpers
- duplicate queue helpers
- old CT101 frontend job pages
- obsolete wrapper compatibility routes
- obsolete SQLite tables

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5E-14 constraints

Do not:

- add heartbeat endpoints yet
- add recovery endpoints yet
- change schemas
- modify CT101 worker code
- restart services
- change Docker Compose
- run persistent workers
- migrate production jobs
- claim real jobs
- change chat behavior
- change study behavior
