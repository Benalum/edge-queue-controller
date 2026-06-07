# Chat-Only Migration Map — Stage 5F-2

## Purpose

Stage 5F-2 maps the first real production chat migration before implementation.

This stage is inspection and planning only.

No production chat behavior changes happen in this stage.

## Inputs

This map builds on:

- docs/first-production-chat-migration-plan.md
- docs/chat-only-migration-inspection-notes.md
- docs/laptop-owned-data-plan.md
- docs/ct101-to-laptop-migration-map.md
- docs/single-frontend-owner-plan.md

## Current direction

The first production migration target remains:

- normal chat
- job type: ollama_chat

Study, companion study, calendar, and profile migration remain postponed.

## Source-of-truth target

The target final ownership for user-facing normal chat is:

- laptop/controller owns visible chat UI
- laptop/controller owns user-facing chat records
- laptop/controller owns app_chats
- laptop/controller owns app_messages
- laptop/controller owns durable app_jobs
- CT101 executes model work and returns result_json
- CT101 does not own final user-facing normal chat state after cutover

## Current safe implementation sequence

The safest implementation sequence should be:

1. keep current chat behavior unchanged
2. add laptop chat queue feature flag
3. add laptop-side chat job creation helper
4. add laptop-side queued chat status/read helper
5. add synthetic/local smoke for chat job creation
6. add synthetic/local smoke for assistant message persistence
7. add CT101 bounded real Ollama execution smoke for chat-shaped payload
8. add opt-in UI path
9. test rollback by disabling the feature flag
10. only then consider promoting the queued path

## Required feature flags

Default must remain off.

Recommended flags:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_MODE=opt_in
- LAPTOP_CHAT_QUEUE_JOB_TYPE=ollama_chat
- LAPTOP_CHAT_QUEUE_ROLLBACK_ENABLED=1

No production chat route should require laptop queue unless LAPTOP_CHAT_QUEUE_ENABLED=1.

## Chat request contract

A future laptop queued chat request should include:

- user_id from authenticated session
- chat_id if continuing an existing chat
- message content
- requested model
- mode: chat
- metadata needed for rendering and debugging

The server must derive user_id from the session.

The client must not be trusted to choose user_id.

## Queue payload contract

The app_jobs.payload_json for queued chat should contain:

- prompt or messages
- chat_id
- user_message_id
- mode: chat
- synthetic: false only after production enablement
- route_source
- requested_model

Do not include secrets, session tokens, cookies, or raw auth headers in payload_json.

## Queue result contract

The CT101 worker should return result_json with:

- reply
- model
- worker
- mode
- elapsed_seconds
- source

The laptop chat persistence layer should read result_json.reply and create exactly one assistant message.

## Assistant message persistence rule

Assistant messages should be created only when:

- job status is complete
- result_json.reply is non-empty
- job belongs to the authenticated user
- referenced chat belongs to the authenticated user
- assistant message has not already been created for that job

A failed job must not create an assistant message.

A duplicate complete must not create duplicate assistant messages.

## Data model gap

Current app_jobs does not yet have an assistant_message_id or idempotency key.

Before production chat persistence, consider adding one of:

- app_jobs.result_message_id
- app_messages.source_job_id unique
- app_messages.metadata_json with source_job_id plus unique index

Recommended first production-safe option:

- add source_job_id to app_messages
- enforce uniqueness on source_job_id

Do not add this schema change in Stage 5F-2.

## Frontend behavior target

The wrapper chat page should show:

- queued
- running
- completed assistant reply
- failed job message
- retry option later
- server offline/queued state when CT101 is offline

The UI must remain responsive.

## Rollback behavior

Rollback should be:

1. set LAPTOP_CHAT_QUEUE_ENABLED=0
2. leave current chat route/path active
3. keep old CT101 chat path available
4. do not delete CT101 chat routes
5. do not delete CT101 jobs tables
6. do not delete CT101 frontend pages yet

## Required future smokes

Before enabling production chat queue:

- chat queue feature flag off smoke
- chat queue feature flag on smoke
- queued chat job creation smoke
- queued chat status smoke
- assistant message persistence smoke
- failed job no assistant message smoke
- duplicate completion no duplicate assistant smoke
- rollback flag smoke
- CT101 offline queued state smoke
- backup before schema change smoke

## Recommended Stage 5F-3

Stage 5F-3 should be schema planning for idempotent assistant message persistence.

Recommended:

- inspect app_messages schema
- decide source_job_id or metadata strategy
- add migration plan only
- add static smoke only

Do not implement production queued chat yet.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

Cleanup candidates after full migration:

- old CT101 queue routes
- CT101 local jobs table usage
- old CT101 frontend chat pages
- duplicate queue helpers
- obsolete wrapper compatibility routes
- obsolete SQLite tables

## Stage 5F-2 constraints

Do not:

- change production chat behavior
- add production queued chat route
- add schema changes
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
