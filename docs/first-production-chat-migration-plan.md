# First Production Chat Migration Plan — Stage 5F-1

## Purpose

Stage 5F-1 plans the first opt-in production migration from the old CT101 queue/chat path to the laptop-owned queue.

This stage is planning only.

No production chat behavior changes in this stage.

## Current proven foundation

Already proven:

- laptop Postgres foundation exists
- laptop app queue schema exists
- laptop queue backup tooling exists
- laptop internal queue API exists
- laptop queue token hardening works
- CT101 can reach laptop queue over Tailscale
- CT101 can claim/complete/fail synthetic laptop jobs
- CT101 bounded synthetic poller works
- CT101 bounded real Ollama poller works
- CT101 bounded Ollama failure handling works
- worker register/heartbeat works
- synthetic recovery works
- idempotent completion works

## Migration target

The first real production job type should be:

- normal chat / ollama_chat

Do not migrate study grading first.

Do not migrate companion study first.

Do not migrate calendar first.

Normal chat is the safest first production candidate because:

- it has a clear request/result shape
- it already maps to `ollama_chat`
- it can be feature-flagged
- rollback can return to the current direct/CT101 path

## Required feature flags

Production chat migration must be opt-in.

Recommended flags:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_MODE=opt_in
- LAPTOP_CHAT_QUEUE_JOB_TYPE=ollama_chat
- LAPTOP_CHAT_QUEUE_ROLLBACK_ENABLED=1

Default behavior must remain unchanged unless the flag is explicitly enabled.

## Required route behavior

The future chat route should support two paths:

### Current path

The current synchronous or CT101-backed chat path remains default.

### Laptop queue path

When explicitly enabled:

1. create user message
2. create laptop queue job
3. return job id and queued status
4. frontend polls job status
5. on completion, persist assistant message
6. display assistant message

## Result contract

The laptop queue chat job result_json should contain:

- reply
- model
- worker
- mode
- elapsed_seconds
- source

The chat layer should persist:

- assistant message content from result_json.reply
- model from result_json.model
- risk_level if available
- created_at from server-side timestamp

Do not trust arbitrary result_json fields for user/session ownership.

## Ownership rule

Laptop/controller should become the source of truth for user-facing chat state.

CT101 should eventually become:

- worker/model executor
- Ollama host
- optional backend helper

CT101 should not remain the long-term owner of user chat data after migration.

## Rollback rule

Rollback must be simple.

If laptop queued chat fails:

- disable LAPTOP_CHAT_QUEUE_ENABLED
- current chat path remains available
- no Docker Compose change should be required
- no production worker loop change should be required

Do not delete old CT101 routes until production laptop chat has been stable and verified.

## Data safety

Before enabling production laptop queued chat:

- run laptop Postgres backup
- verify app_chats/app_messages schema
- verify user/session ownership
- verify assistant message persistence
- verify duplicate completion does not duplicate assistant messages
- verify failed jobs do not create assistant messages

## Frontend behavior

The frontend should show:

- queued
- running
- complete
- failed
- retry/rollback message when failed

The frontend must not freeze while CT101/server is working.

If CT101 is offline:

- laptop wrapper still loads
- chat job can remain queued
- UI shows server offline/queued state

## Required smokes before implementation

Before real chat cutover:

- queued chat creation smoke
- queued chat polling smoke
- assistant message persistence smoke
- failed job does not create assistant smoke
- duplicate completion does not duplicate assistant smoke
- rollback flag smoke
- CT101 offline queued state smoke

## Recommended Stage 5F-2

Stage 5F-2 should be implementation-planning or inspection for current chat routes.

Recommended:

- inspect wrapper chat route
- inspect CT101 chat route
- inspect current auth/session mapping
- inspect app_chats/app_messages usage
- inspect where assistant messages are persisted today
- produce exact migration map for chat only

Do not implement production chat migration in Stage 5F-2 unless the inspection is clean.

## What must remain postponed

Postpone:

- study migration
- companion migration
- calendar migration
- persistent CT101 production polling
- Docker Compose worker changes
- cleanup of CT101 queue
- deletion of old frontend pages
- deletion of old databases/tables

## Cleanup requirement

After full migration is complete and verified, remove unused legacy pieces in a separate cleanup stage.

Cleanup candidates:

- old CT101 queue routes
- CT101 local jobs table usage
- old CT101 frontend pages
- duplicate smoke helpers
- obsolete wrapper compatibility routes
- obsolete SQLite tables

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5F-1 constraints

Do not:

- change production chat behavior
- add production chat queue route
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
