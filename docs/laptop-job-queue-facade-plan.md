# Laptop-Owned Job Queue Facade Plan — Stage 5E-1

## Purpose

Stage 5E-1 plans the laptop-owned job queue facade before connecting CT101 workers to laptop Postgres.

This stage is documentation and smoke checks only.

No worker behavior changes happen in this stage.

## Current state

The laptop/controller now has a Postgres foundation with these empty app tables:

- app_users
- app_sessions
- app_chats
- app_messages
- app_jobs
- app_workers
- app_worker_nodes

The controller runtime still uses SQLite for current live controller behavior:

- edge_queue.sqlite3

CT101 still owns the current production AI Platform app data and job processing behavior.

## Target queue ownership

The target architecture is:

- laptop/controller owns durable app_jobs
- laptop/controller owns durable app_workers
- laptop/controller owns durable app_worker_nodes
- CT101 workers become execution nodes
- CT101 workers claim jobs from the laptop/controller
- CT101 workers send job results back to the laptop/controller
- CT101 jobs table becomes temporary, runtime-only, or removed after migration

## Why the queue moves first

The job queue should move before full chat/study migration because it unlocks the main offline behavior:

- user can submit work while CT101 is offline
- job remains queued on the laptop
- CT101 processes the job when it wakes or comes online
- user can see pending/running/complete/failed state from alexhartel.com

## Facade concept

A queue facade is a laptop/controller API layer that exposes job operations without immediately forcing every UI feature to migrate.

Future laptop-owned facade endpoints may include:

- POST /api/controller/jobs
- GET /api/controller/jobs
- GET /api/controller/jobs/{job_id}
- POST /api/controller/internal/workers/register
- POST /api/controller/internal/workers/heartbeat
- POST /api/controller/internal/jobs/claim
- POST /api/controller/internal/jobs/{job_id}/complete
- POST /api/controller/internal/queue/recover
- GET /api/controller/internal/queue/summary

Endpoint names are not final in this stage.

## Worker authentication plan

CT101 workers need a laptop/controller worker credential.

Requirements:

- token stored outside git
- token scoped to worker endpoints only
- no user credentials embedded in worker containers
- logs must not print the token
- worker registration and heartbeat must verify the token
- future rotation process should exist

## Job lifecycle

Target laptop-owned lifecycle:

1. queued
2. running
3. complete
4. failed
5. cancelled

Required fields already exist in the laptop schema foundation:

- id
- user_id
- job_type
- status
- requested_model
- assigned_worker_id
- payload_json
- result_json
- error_text
- created_at
- updated_at
- started_at
- finished_at

Future fields may be added later:

- priority
- retry_count
- max_retries
- lease_expires_at
- idempotency_key
- cancelled_at
- cancellation_reason

Do not add those fields until a later planned schema stage.

## First job types to support

The safest first job type is:

- ollama_chat

Reason:

- queued chat backend smoke already exists on CT101
- chat can be tested with synthetic data
- chat response idempotency has already been proven in Stage 4G

Next job types can include:

- companion_study_grade
- study helper/explain
- calendar summarization
- future image/video jobs

## Avoiding duplicate queues

During migration, only one system can own an active job queue for a given job path.

Safe transition plan:

1. laptop queue facade is created but not used by production UI
2. isolated synthetic laptop queue lifecycle smoke passes
3. CT101 worker can claim a synthetic laptop job
4. CT101 worker can complete a synthetic laptop job
5. one opt-in UI path uses laptop queue
6. production path is migrated one domain at a time
7. CT101 queue is deprecated only after comparisons and rollback are ready

Do not let both CT101 and laptop queues accept the same production job type at the same time unless an idempotency key exists.

## Recovery behavior

Laptop/controller should own recovery because it owns the durable queue.

Recovery should eventually handle:

- stale workers
- running jobs assigned to stale workers
- jobs stuck in running state
- jobs that exceeded lease timeout
- cancelled jobs
- failed jobs that can be retried

Stage 5E-1 does not implement recovery.

## UI behavior target

When CT101 is offline:

- user can still create a job
- job status remains queued
- system page says CT101 is offline or booting
- job page says waiting for worker

When CT101 is online:

- worker claims job
- job changes to running
- worker completes or fails job
- UI updates from laptop/controller state

## Required smokes before behavior changes

Before connecting CT101 workers to laptop jobs, add:

- laptop app_jobs schema smoke
- synthetic laptop job insert/read/delete smoke
- synthetic laptop job claim/complete helper smoke
- worker token static marker smoke
- no-secret-in-repo smoke for worker token path
- backup smoke before schema changes
- queue recovery planning smoke

## Cleanup requirement after migration

After laptop queue ownership is live and verified, a later cleanup stage must remove unused legacy job queue pieces.

Cleanup should review:

- CT101 jobs table usage
- CT101 job routes
- duplicate job helper functions
- old CT101 job smokes
- old frontend jobs pages
- obsolete wrapper proxy routes
- obsolete SQLite queue tables
- old queue docs that no longer apply

Cleanup must wait until:

- laptop queue is source of truth
- CT101 workers use laptop queue
- production jobs are verified
- backups pass
- restore is tested
- rollback instructions exist

## Stage 5E-1 constraints

Do not:

- modify CT101
- connect CT101 workers to laptop yet
- migrate production jobs
- change controller runtime behavior
- change user-facing behavior
- add new schema fields
- remove old queues
- remove old websites
- change power automation
