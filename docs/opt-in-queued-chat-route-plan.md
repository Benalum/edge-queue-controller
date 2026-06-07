# Opt-In Queued Chat Route Plan — Stage 5F-6

## Purpose

Stage 5F-6 plans the first opt-in queued chat route behavior.

This stage is planning only.

No production chat behavior changes happen in this stage.

## Current proven foundation

Already proven:

- laptop queue foundation exists
- CT101 bounded Ollama success path works
- CT101 bounded Ollama failure path works
- app_messages.source_job_id schema exists
- assistant-message persistence helper is idempotent
- failed jobs do not create assistant messages
- duplicate persistence does not create duplicate assistant messages

## Target behavior

The future queued chat route should be disabled by default.

When enabled, it should:

1. authenticate user from session
2. create or reuse app_chats row
3. create user app_messages row
4. create app_jobs row with job_type ollama_chat
5. return queued job status to frontend
6. let frontend poll job status
7. persist assistant message exactly once after job completion

## Required feature flags

Default must remain off.

Recommended flags:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_MODE=opt_in
- LAPTOP_CHAT_QUEUE_JOB_TYPE=ollama_chat
- LAPTOP_CHAT_QUEUE_ROLLBACK_ENABLED=1

## Proposed future endpoints

Future endpoints may include:

- POST /api/chat/queued
- GET /api/chat/queued/{job_id}
- POST /api/chat/queued/{job_id}/persist

These endpoints should not be added in Stage 5F-6.

## Request contract

A future queued chat request should contain:

- message
- chat_id optional
- requested_model optional

The server must derive user_id from the authenticated session.

The client must not be trusted to provide user_id.

## Job payload contract

Future app_jobs.payload_json should contain:

- chat_id
- user_message_id
- prompt or messages
- mode chat
- route_source
- synthetic false only after production enablement

Do not include cookies, tokens, secrets, raw auth headers, or passwords.

## Status response contract

Queued chat status should expose:

- job_id
- status
- chat_id
- user_message_id
- assistant_message_id if persisted
- error_text if failed
- result preview only when safe

## Persistence rule

Assistant message persistence should use edge_modules.chat_queue_persistence behavior.

It should create exactly one assistant message for one completed job.

Failed jobs must not create assistant messages.

Duplicate persistence must return the existing assistant message.

## Rollback rule

Rollback should be simple:

1. set LAPTOP_CHAT_QUEUE_ENABLED=0
2. keep current chat path active
3. leave existing queued jobs visible for debugging
4. do not delete CT101 routes
5. do not delete CT101 jobs tables

## Frontend behavior target

The frontend should show:

- queued
- running
- complete
- failed
- server offline but job queued

The UI must remain responsive.

## Recommended Stage 5F-7

Stage 5F-7 should inspect current wrapper chat routes and add a disabled-by-default route skeleton.

The route skeleton should return 404 or feature_disabled unless LAPTOP_CHAT_QUEUE_ENABLED=1.

Stage 5F-7 should not send real production jobs yet.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5F-6 constraints

Do not:

- change production chat behavior
- add active production queued chat route
- create real production chat jobs
- persist assistant messages from real jobs
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
