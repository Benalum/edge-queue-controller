# Real-User Queued Chat Guard Plan — Stage 5F-11

## Purpose

Stage 5F-11 plans the guardrails required before queued chat can accept real authenticated users.

This stage is planning only.

No production chat behavior changes happen in this stage.

## Current proven foundation

Already proven:

- synthetic route-created queued chat jobs work
- CT101 bounded Ollama poller can complete route-created queued jobs
- assistant message persistence is idempotent
- failed jobs do not create assistant messages
- duplicate persistence returns the same assistant message
- queued chat route remains disabled by default
- enabled route currently requires synthetic-only mode

## Problem being solved

The next migration risk is allowing real authenticated users into the queued chat path safely.

Before that can happen, the controller must have a strict auth/session ownership guard.

## Required production guard behavior

A future real-user queued chat route must:

1. derive user_id from the authenticated session
2. reject any client-provided user_id
3. verify chat ownership before reusing chat_id
4. create user message only for the authenticated user
5. create queued job only for the authenticated user
6. return only job status owned by the authenticated user
7. persist assistant message only for jobs owned by the authenticated user

## Feature flags

Default must remain off.

Recommended flags:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=0
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_ROLLBACK_ENABLED=1

Real-user queued chat must require LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1.

Enabling LAPTOP_CHAT_QUEUE_ENABLED alone must not be enough for real users.

## Route behavior target

Future route behavior should be:

- feature disabled: 404 feature_disabled
- enabled but neither synthetic nor real-user mode: 501 synthetic_only_required_stage_5f9 or real_user_guard_required
- synthetic mode enabled: allow only synthetic guarded test users
- real-user mode enabled: allow only authenticated session-derived users

## Ownership checks

GET /api/chat/queued/{job_id} must only return jobs owned by the authenticated user.

POST /api/chat/queued must not accept X-Synthetic-User-Id in real-user mode.

POST /api/chat/queued must not accept user_id in JSON.

Existing chat reuse must require app_chats.user_id = authenticated user id.

## Persistence checks

Assistant persistence must require:

- job.status = complete
- job.user_id = authenticated user id
- chat belongs to authenticated user
- source_job_id has no existing different assistant message
- result_json.reply is non-empty

## Required future smokes

Before real-user queued chat can be enabled:

- real-user feature flag off smoke
- real-user feature flag on but unauthenticated smoke
- authenticated queued chat creation smoke
- wrong-user chat reuse refused smoke
- wrong-user job status refused smoke
- failed job no assistant message smoke
- duplicate persistence same assistant message smoke
- rollback disables queued chat smoke

## Recommended Stage 5F-12

Stage 5F-12 should inspect the current wrapper auth/session helpers and document the exact session-derived user_id function to use.

Stage 5F-12 should still not enable real-user queued chat.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5F-11 constraints

Do not:

- enable real-user queued chat
- create real production chat jobs
- persist assistant messages from real user jobs
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- start persistent workers
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior
