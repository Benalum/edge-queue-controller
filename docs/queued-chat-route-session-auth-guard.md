# Queued Chat Route Session Auth Guard — Stage 5F-17

## Purpose

Stage 5F-17 wires the queued chat route to the session-auth resolver only far enough to prove real-user authentication can be resolved.

This stage does not create real production queued chat jobs.

This stage does not change default production chat behavior.

## Behavior

When queued chat is disabled:

- routes still return feature_disabled

When synthetic mode is enabled:

- synthetic queued chat route behavior still works

When real-user mode and session-auth resolver are enabled:

- POST /api/chat/queued resolves authenticated_user_id from the session token
- POST /api/chat/queued refuses missing/invalid session tokens
- POST /api/chat/queued refuses client-provided user_id
- POST /api/chat/queued returns real_user_job_creation_not_wired_stage_5f17 after successful auth
- no real jobs are created
- no assistant messages are persisted

## Required flags for real-user route auth smoke

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1

## Safety

This stage proves route-level auth only.

It does not create jobs.

It does not persist messages.

It does not call CT101.

It does not call Ollama.

## What this stage does not do

This stage does not:

- enable real-user queued chat by default
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

## Next stage

Stage 5F-18 should add a real-user queued chat creation helper that can create jobs only behind explicit flags and smoke data.

Production queued chat should remain disabled unless explicitly enabled.
