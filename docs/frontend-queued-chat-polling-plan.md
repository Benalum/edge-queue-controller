# Frontend Queued Chat Polling Plan — Stage 5F-26

## Purpose

Stage 5F-26 plans the frontend behavior for real-user queued chat polling and status display.

This stage is planning only.

This stage does not change frontend runtime behavior.

This stage does not enable queued chat by default.

## Current proven backend foundation

Already proven:

- real-user POST /api/chat/queued creates an owned queued job behind explicit flags
- real-user GET /api/chat/queued/{job_id} returns only owned job status
- wrong-user status lookup is refused
- rollback/offline behavior leaves jobs queued and creates no assistant message
- CT101 bounded one-shot can complete real-user-shaped jobs
- assistant persistence is idempotent after completion

## Frontend behavior target

Future frontend queued chat should:

1. submit user message to POST /api/chat/queued only when queued chat mode is enabled
2. immediately render the user message locally
3. show assistant placeholder state while job status is queued
4. poll GET /api/chat/queued/{job_id} until status is complete or failed
5. stop polling after a bounded timeout or failed status
6. show offline/queued state if CT101 is not processing jobs
7. show failed state if job status becomes failed
8. render assistant message only after completed result is available
9. avoid duplicate assistant messages on page refresh or repeated polling
10. preserve legacy/current chat behavior when queued chat is disabled

## Required frontend states

The UI should support these states:

- sending
- queued
- running
- complete
- failed
- offline_or_waiting
- timed_out
- cancelled_or_rolled_back

## Polling rules

Recommended first polling behavior:

- poll every 2 seconds for the first 30 seconds
- then every 5 seconds up to 2 minutes
- stop after timeout and show still queued/offline message
- allow user to refresh status manually
- do not submit duplicate jobs while one message is already queued

## Rollback behavior

If queued chat is disabled or errors occur, the frontend should fall back to the existing non-queued chat path.

Frontend rollback must not delete existing queued jobs.

Frontend rollback must not create duplicate messages.

## Security behavior

The frontend must not send user_id.

The frontend must not send X-Synthetic-User-Id in real-user mode.

The frontend should rely on normal authenticated session behavior.

## What this stage does not do

This stage does not:

- change frontend runtime behavior
- enable queued chat by default
- submit real production queued jobs
- start persistent workers
- call CT101
- call Ollama directly
- persist assistant messages
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Recommended Stage 5F-27

Stage 5F-27 should add a disabled-by-default frontend queue status helper or static UI markers.

Production queued chat should remain disabled unless explicitly enabled.
