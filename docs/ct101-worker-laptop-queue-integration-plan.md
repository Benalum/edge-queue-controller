# CT101 Worker Laptop Queue Integration Plan — Stage 5E-9

## Purpose

Stage 5E-9 inspects CT101 worker/job code and plans the smallest safe synthetic-only worker integration with the laptop/controller queue.

This stage is inspection and planning only.

No CT101 files are modified.

## Current proven foundation

The laptop/controller queue path has already proven:

- laptop Postgres foundation exists
- laptop app queue schema exists
- laptop queue helper can claim/complete/fail synthetic jobs
- internal laptop queue API exists
- internal laptop queue API is token protected
- CT101 can reach laptop queue summary with token
- CT101 can claim/complete/fail synthetic laptop jobs through the laptop API

## Current CT101 role

CT101 currently remains the production AI Platform backend and worker host.

CT101 still owns current production app behavior for:

- normal AI Platform backend routes
- current worker process
- current CT101 job queue behavior
- current Ollama/model execution path
- current Study/Companion behavior

## Target future role

CT101 should become execution-only for laptop-owned jobs.

Future direction:

- laptop/controller owns durable app_jobs
- laptop/controller owns app_workers and app_worker_nodes
- CT101 worker claims jobs from laptop/controller
- CT101 worker sends results back to laptop/controller
- CT101 local jobs table becomes temporary, runtime-only, deprecated, or removed later

## Files inspected

The read-only inspection report is saved at:

- docs/ct101-worker-laptop-queue-inspection-notes.md

Primary CT101 files inspected:

- backend/app/worker/agent.py
- backend/app/routes/jobs.py
- backend/app/routes/worker_status.py
- backend/app/routes/worker_nodes.py
- backend/app/routes/chat.py
- backend/app/routes/companion_study.py
- backend/app/db/models.py
- docker-compose.yml
- ops/smoke

## Integration principle

Do not replace the current CT101 worker loop directly.

First add an explicitly opt-in synthetic-only laptop queue mode.

The mode should be disabled by default.

## Proposed future CT101 env flags

Future CT101 synthetic-only mode should require all of these:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_BASE_URL=http://100.108.171.94:7070 or a staged smoke port
- LAPTOP_QUEUE_TOKEN_FILE=/opt/ai-platform/.secrets/laptop-queue.env
- LAPTOP_QUEUE_WORKER_ID=ct101-synthetic-worker
- LAPTOP_QUEUE_JOB_TYPES=ollama_chat

The exact base URL and worker id can change in implementation.

## Synthetic-only safety rule

When LAPTOP_QUEUE_SYNTHETIC_ONLY=1, the CT101 worker must only claim job IDs or payloads that are clearly synthetic.

Recommended guardrails:

- only claim jobs created by smoke setup endpoints
- require job id prefix such as s5e or synthetic
- require payload_json marker such as "synthetic": true in a later schema/API version
- never claim production user jobs in synthetic mode

Because current Stage 5E synthetic setup creates IDs with stage prefixes, the next implementation may initially enforce prefix-based safety.

## Recommended Stage 5E-10 scope

Stage 5E-10 should add a synthetic-only CT101 worker client module or script.

Recommended implementation:

- add a CT101-side script under /opt/ai-platform/ops/smoke or backend helper
- it reads /opt/ai-platform/.secrets/laptop-queue.env
- it calls laptop /internal/laptop-queue/jobs/claim
- it refuses jobs without a synthetic/stage prefix
- it completes/fails exactly one synthetic job
- it exits immediately
- it is run only by smoke test
- it does not alter the always-running CT101 worker service

## What Stage 5E-10 should not do

Do not:

- modify the main CT101 worker loop yet
- change Docker Compose
- restart services
- migrate production jobs
- change normal chat routing
- change Study/Companion routing
- claim non-synthetic jobs
- delete CT101 job tables
- remove old CT101 routes

## Later integration stages

After Stage 5E-10 synthetic one-shot succeeds:

### Stage 5E-11

Add CT101 worker client as dormant code behind env flags.

### Stage 5E-12

Add one-shot laptop queue worker smoke using synthetic jobs only.

### Stage 5E-13

Add opt-in worker service mode, still synthetic-only.

### Stage 5F

Plan production job type migration.

### Stage 5G

Migrate one job type behind an opt-in feature flag.

## Risks

Highest-risk areas:

- duplicate queues accepting the same production job
- CT101 worker claiming production laptop jobs before user/auth migration is ready
- lost assistant messages if chat result persistence is not idempotent
- stale running jobs if laptop queue recovery is not active
- token leakage in logs or git
- confusing two sources of truth during transition
- power automation interrupting long jobs if worker state is not reported correctly

## Required before production migration

Before any real production job moves to laptop queue:

- synthetic CT101 worker smoke passes
- laptop queue recovery behavior exists
- worker heartbeat behavior exists against laptop queue
- idempotency/duplicate completion behavior is defined
- rollback plan exists
- backups pass
- restore is tested
- UI displays queued/running/failed correctly from laptop source of truth

## Cleanup requirement

After laptop queue migration is complete and verified, a later cleanup stage must remove unused legacy pieces.

Review for removal:

- CT101 local jobs table usage
- CT101 job routes no longer needed
- duplicate queue helper functions
- old CT101 frontend job pages
- obsolete wrapper proxy routes
- stale smoke scripts
- old compatibility docs

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5E-9 constraints

Do not:

- modify CT101 files
- run migrations
- restart services
- change Docker Compose
- change current worker loop
- connect production jobs to laptop queue
- change normal chat behavior
- change Study/Companion behavior
