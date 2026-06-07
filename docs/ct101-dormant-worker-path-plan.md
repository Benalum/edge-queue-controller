# CT101 Dormant Env-Flagged Worker Path Plan — Stage 5E-13

## Purpose

Stage 5E-13 plans the smallest safe path for adding a dormant laptop-queue worker mode to CT101.

This stage is planning only.

No CT101 files are modified in this stage.

## Current proven foundation

Already proven:

- laptop Postgres app queue schema exists
- laptop internal queue API exists
- laptop internal queue API is token protected
- CT101 can reach laptop queue API over Tailscale
- CT101 can claim/complete/fail synthetic laptop jobs
- CT101 one-shot worker helper works
- CT101 dormant laptop queue client works
- CT101 dormant client one-shot smoke works

## Inspection notes

Read-only inspection notes are saved at:

- docs/ct101-dormant-worker-path-inspection-notes.md

Primary CT101 files inspected:

- backend/app/worker/agent.py
- backend/app/worker/laptop_queue_client.py
- ops/smoke/laptop_queue_client_one_shot.py
- ops/smoke/laptop_queue_one_shot_worker.py
- docker-compose.yml

## Target future worker architecture

The future architecture should support two worker modes:

### Current mode

CT101 worker uses current CT101 job endpoints and CT101 database-backed queue.

### Dormant laptop queue mode

CT101 worker uses laptop/controller queue endpoints when explicitly enabled.

It must be disabled by default.

## Required future env flags

A future dormant worker path should require:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1 for pre-production
- LAPTOP_QUEUE_BASE_URL
- LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
- LAPTOP_QUEUE_WORKER_ID
- LAPTOP_QUEUE_JOB_TYPE or LAPTOP_QUEUE_JOB_TYPES
- LAPTOP_QUEUE_MODE=one-shot or poll

No production mode should be allowed without a later explicit stage.

## Suggested future insertion point

Do not replace the current worker loop directly.

Recommended staged path:

1. Add a separate function in CT101 worker code, such as `run_laptop_queue_worker_once`.
2. Keep the function dormant unless env flags are present.
3. Add a smoke that calls only this function in one-shot mode.
4. Add synthetic-only polling later, still disabled by default.
5. Only after recovery/heartbeat/idempotency are proven, plan production job migration.

## Synthetic-only guardrails

Pre-production laptop queue worker mode must:

- require LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- refuse non-synthetic job IDs
- allow only known synthetic prefixes
- exit immediately in one-shot smoke mode
- never claim production jobs
- never run automatically from Docker Compose

## Required before persistent polling

Before CT101 has any persistent laptop queue poller, the system needs:

- laptop queue heartbeat endpoint
- laptop worker registration endpoint
- laptop queue recovery behavior
- stale worker detection
- stuck running job recovery
- idempotent completion behavior
- duplicate completion handling
- clear worker shutdown behavior
- observability route for laptop queue workers
- rollback path to current CT101 queue

## Required before production job migration

Before moving real chat/study jobs to laptop queue:

- persistent synthetic worker mode passes
- heartbeat/recovery passes
- queue summary accurately shows laptop source of truth
- UI can show queued/running/complete/failed from laptop
- production job result persistence is idempotent
- CT101 old queue and laptop queue cannot both accept same production job type
- backup/restore is tested
- rollback plan is documented

## Recommended Stage 5E-14 scope

Stage 5E-14 should still be small.

Recommended:

- add CT101 documentation for a future dormant worker function
- add static smoke checking exact env flags and guardrail markers
- do not change the production worker loop
- do not change Docker Compose
- do not restart services

Alternative if implementation proceeds:

- add a new CT101 smoke-only script that imports `LaptopQueueClient`
- run one synthetic job
- exit immediately
- no service changes

## What must be postponed

Postpone:

- Docker Compose changes
- real worker service changes
- persistent polling
- production chat migration
- production study migration
- queue cleanup
- CT101 database cleanup
- old route removal
- frontend queue switch

## Rollback plan

Because Stage 5E-13 is documentation only:

- revert the controller commit
- no CT101 rollback needed
- no database rollback needed
- no service restart needed

For later implementation stages:

- keep current CT101 worker loop unchanged until explicit cutover
- keep laptop queue migration behind env flags
- retain current CT101 queue routes until production migration is verified
- keep backups before any schema or data migration

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

## Stage 5E-13 constraints

Do not:

- modify CT101 files
- modify production worker loop
- restart services
- change Docker Compose
- run persistent workers
- migrate production jobs
- claim real jobs
- change chat behavior
- change study behavior
