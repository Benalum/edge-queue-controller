# Laptop-Owned Data Architecture Plan — Stage 5B

## Purpose

Stage 5B plans the next architecture pivot:

- The laptop/controller becomes the source of truth for user-facing data.
- CT101 becomes a worker/model execution node.
- Users can log in, view saved data, create data, and queue work even when CT101 is offline.
- CT101 processes queued work when it is online.

This stage is documentation and smoke checks only.

## Target architecture

User-facing flow:

1. User opens alexhartel.com.
2. Laptop/controller serves the public wrapper UI.
3. Laptop/controller handles auth/session and app data.
4. Laptop/controller stores queued jobs.
5. CT101 worker polls or receives jobs from the laptop/controller.
6. CT101 runs Ollama/model work.
7. CT101 sends results back to the laptop/controller.
8. User sees completed results in the same website UI.

## High-level ownership

Laptop/controller owns:

- public website shell
- auth/session source of truth
- user profiles
- study decks
- study cards
- study reviews
- chat threads
- chat messages
- calendar events
- queued jobs
- job status
- worker status summary
- credits and public account state
- system/power status

CT101 owns:

- Ollama/model execution
- worker runtime
- model files
- optional local model cache
- optional temporary job scratch data
- optional dev-only frontend during migration

## Why this is useful

When CT101 is offline, the website can still work.

Users can:

- log in
- view existing data
- create decks/cards
- write chat messages
- create calendar items
- submit AI requests into the queue
- see pending jobs
- see server offline/booting/online status

When CT101 is online, workers can drain queued jobs and return results.

## Expected speed impact

The extra laptop-to-server data hop should usually be small compared with model inference time.

Most job payloads are JSON and should be much smaller than the time required for:

- model loading
- prompt processing
- generation
- grading
- image/video generation in future stages

## Main tradeoff

The laptop becomes the primary source of truth.

That means the laptop needs:

- reliable database storage
- backups
- restore instructions
- careful migrations
- health checks
- disk monitoring

## Recommended database direction

Use Postgres on the laptop/controller as the long-term app database.

SQLite is acceptable for controller metadata and small local state, but Postgres is better for:

- multi-user auth/session data
- chats/messages
- study cards/reviews
- calendar data
- durable job queue
- worker status
- future scaling

## Current CT101 data categories to migrate later

Current CT101-owned app data that should eventually move to laptop/controller:

- users
- user sessions
- chats
- messages
- companion profiles
- user profiles
- study decks
- study cards
- study reviews
- calendar events
- jobs
- workers
- worker nodes

Current CT101-owned compute/runtime data that can remain CT101-side:

- Ollama model files
- worker process state
- temporary worker scratch files
- GPU/CPU runtime details
- model execution logs
- optional local cache

## Future worker protocol

The final worker protocol should look like:

1. Worker registers with laptop/controller.
2. Worker heartbeats to laptop/controller.
3. Worker claims a queued job from laptop/controller.
4. Worker downloads the job payload/context.
5. Worker runs the model/tool.
6. Worker posts completion or failure back to laptop/controller.
7. Laptop/controller updates the source-of-truth database.
8. Wrapper UI updates from laptop/controller state.

## Failure behavior

If CT101 is offline:

- jobs remain queued
- user data remains available
- UI shows server offline or booting
- no data is lost

If a worker dies while running a job:

- laptop/controller marks worker stale/offline
- stuck jobs are recovered or failed
- user sees failed or retryable status

If the laptop/controller is offline:

- public site is unavailable
- CT101 should not become an alternate source of truth
- data restore depends on laptop/controller backups

## Backup requirement

Before moving source-of-truth data to the laptop, add backups.

Minimum acceptable backup plan:

- daily Postgres dump
- keep last 7 daily backups
- keep weekly snapshots
- store backup copies off the laptop when possible
- document restore command
- smoke check that backup files exist and are non-empty

## Migration phases

### Stage 5B

Plan laptop-owned data architecture.

No runtime behavior changes.

### Stage 5C

Inspect current CT101 schema and define a table-by-table migration map.

No data migration yet.

### Stage 5D

Add laptop-side database foundation.

This may include Postgres or a clearly documented temporary SQLite/Postgres bridge.

### Stage 5E

Add laptop-owned job queue facade.

CT101 workers still run jobs, but laptop/controller owns queued job state.

### Stage 5F

Move chat source of truth to laptop/controller.

CT101 becomes chat worker/model executor.

### Stage 5G

Move study source of truth to laptop/controller.

CT101 grades or explains study cards as a worker.

### Stage 5H

Move calendar/profile source of truth to laptop/controller.

### Stage 5I

Make CT101 frontend dev-only and remove public dependency on CT101 frontend pages.

## What should not happen yet

Do not:

- move production data yet
- change CT101 database schema
- change laptop database schema
- change auth source of truth yet
- change worker claim behavior yet
- migrate chat yet
- migrate study yet
- remove CT101 frontend yet
- restart services
- deploy
- change power automation
