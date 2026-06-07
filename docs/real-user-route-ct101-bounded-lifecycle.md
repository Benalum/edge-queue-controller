# Real-User Route to CT101 Bounded Lifecycle — Stage 5F-24

## Purpose

Stage 5F-24 proves the first real-user-shaped route to CT101 bounded execution lifecycle.

This stage uses temporary smoke users and sessions.

This stage does not enable persistent workers.

This stage does not change default production behavior.

## Lifecycle proven

The smoke proves:

1. temporary laptop/controller API starts with explicit real-user queued chat flags
2. temporary smoke user and session are created
3. POST /api/chat/queued creates an owned queued app_jobs row
4. GET /api/chat/queued/{job_id} returns queued status for the owner
5. CT101 bounded one-shot poller claims the real-user-shaped queued job
6. CT101 completes the job using Ollama
7. GET /api/chat/queued/{job_id} returns complete status for the owner
8. laptop persists one assistant message from the completed job
9. duplicate persistence returns the same assistant message
10. smoke rows are cleaned up

## Required controller flags

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1

## Required CT101 flags

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_REAL_USER_JOBS_ENABLED=1
- LAPTOP_QUEUE_POLL_MODE=bounded
- LAPTOP_QUEUE_EXECUTION_MODE=ollama
- LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1

## Safety

This smoke uses bounded one-shot CT101 execution only.

Persistent workers are not enabled.

Synthetic-only smokes remain supported.

Real-user queued chat remains disabled by default.

## What this stage does not do

This stage does not:

- enable queued chat by default
- start persistent workers
- process production user traffic
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-25 should add rollback/offline behavior smokes for real-user queued chat.

Production queued chat should remain disabled unless explicitly enabled.
