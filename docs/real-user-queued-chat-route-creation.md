# Real-User Queued Chat Route Creation — Stage 5F-19

## Purpose

Stage 5F-19 wires POST /api/chat/queued to the real-user queued chat creation helper.

This stage does not change default production chat behavior.

## Required flags

Real-user route job creation requires all of these:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1

## Behavior

When all flags are enabled:

- POST /api/chat/queued resolves authenticated_user_id from session token
- POST /api/chat/queued refuses client-provided user_id
- POST /api/chat/queued creates app_chats when chat_id is absent
- POST /api/chat/queued creates user app_messages row
- POST /api/chat/queued creates queued app_jobs row
- POST /api/chat/queued returns job_id, chat_id, user_message_id, and queued status

## Safety

This stage only wires POST job creation.

This stage does not wire real-user GET status.

This stage does not call CT101.

This stage does not call Ollama.

This stage does not persist assistant messages from real user jobs.

## What this stage does not do

This stage does not:

- enable queued chat by default
- run persistent workers
- call CT101 for real-user jobs
- call Ollama for real-user jobs
- persist assistant messages from real user jobs
- migrate real users
- migrate real chat data
- change CT101 worker loop
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-20 should add real-user queued chat status lookup for owned jobs only.

Production queued chat should remain disabled unless explicitly enabled.
