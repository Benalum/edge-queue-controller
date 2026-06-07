# Real-User Queued Chat Status Route — Stage 5F-20

## Purpose

Stage 5F-20 wires GET /api/chat/queued/{job_id} for real-user owned job status lookup.

This stage does not change default production chat behavior.

## Required flags

Real-user status lookup requires:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1

## Behavior

When all required flags are enabled:

- GET /api/chat/queued/{job_id} resolves authenticated_user_id from session token
- missing or invalid session token is refused
- wrong-user job status lookup is refused
- owned job status lookup returns job status
- returned job belongs to authenticated_user_id

## Safety

This stage only wires real-user status lookup.

This stage does not call CT101.

This stage does not call Ollama.

This stage does not complete real-user jobs.

This stage does not persist assistant messages from real-user jobs.

## What this stage does not do

This stage does not:

- enable queued chat by default
- run persistent workers
- call CT101 for real-user jobs
- call Ollama for real-user jobs
- complete real-user jobs
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

Stage 5F-21 should add a real-user route local lifecycle smoke: POST creates an owned queued job and GET returns owned queued status.

Production queued chat should remain disabled unless explicitly enabled.
