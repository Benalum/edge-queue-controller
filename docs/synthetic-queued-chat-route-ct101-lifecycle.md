# Synthetic Queued Chat Route to CT101 Lifecycle — Stage 5F-10

## Purpose

Stage 5F-10 proves the first synthetic end-to-end queued chat lifecycle.

This stage does not change default production chat behavior.

## Lifecycle proven

The smoke proves:

1. temporary laptop/controller API starts with synthetic queued chat enabled
2. synthetic user is created
3. POST /api/chat/queued creates a queued app_jobs row
4. CT101 bounded Ollama poller claims the queued job
5. CT101 completes the job with real Ollama result_json
6. GET /api/chat/queued/{job_id} reads completed job status
7. laptop persists one assistant message from the completed job
8. duplicate persistence returns the same assistant message
9. synthetic rows are cleaned up

## Required flags

The route requires:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1

The CT101 poller requires:

- LAPTOP_QUEUE_ENABLED=1
- LAPTOP_QUEUE_SYNTHETIC_ONLY=1
- LAPTOP_QUEUE_POLL_MODE=bounded
- LAPTOP_QUEUE_EXECUTION_MODE=ollama

## What this stage does not do

This stage does not:

- enable production queued chat by default
- create real production chat jobs
- persist assistant messages from real user jobs
- migrate real users
- migrate real chat data
- start persistent workers
- change Docker Compose
- change CT101 production worker loop
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-11 should plan or implement the first disabled-by-default real-user queued chat route guard.

Production queued chat should remain disabled unless explicitly enabled.
