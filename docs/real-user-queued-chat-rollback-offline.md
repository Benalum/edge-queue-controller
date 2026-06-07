# Real-User Queued Chat Rollback and Offline Behavior — Stage 5F-25

## Purpose

Stage 5F-25 proves rollback and offline behavior for real-user queued chat.

This stage does not call CT101.

This stage does not call Ollama.

This stage does not start persistent workers.

This stage does not change default production behavior.

## Behaviors proven

The smoke proves:

1. queued chat disabled by default returns feature_disabled
2. disabled mode creates no jobs
3. real-user route without creation helper enabled refuses job creation
4. creation-helper rollback mode creates no jobs
5. real-user queued chat with CT101 not running creates a queued job
6. owned GET /api/chat/queued/{job_id} returns queued status
7. wrong-user status lookup is refused
8. no assistant message exists before job completion
9. smoke rows are cleaned up

## Rollback meaning

If real-user queued chat needs to be rolled back, disabling any of these flags should prevent new real-user job creation:

- LAPTOP_CHAT_QUEUE_ENABLED
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED
- LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED

## Offline meaning

If CT101 is offline or not running a poller, the laptop/controller can still accept an explicitly enabled real-user queued chat job.

The job remains queued.

The owner can read queued status.

No assistant message is created until a worker completes the job.

## Safety

Persistent workers are not enabled.

CT101 is not called.

Ollama is not called.

Real-user queued chat remains disabled by default.

## What this stage does not do

This stage does not:

- enable queued chat by default
- start persistent workers
- call CT101
- call Ollama
- complete jobs
- persist assistant messages from incomplete jobs
- migrate real users
- migrate real chat data
- change Docker Compose
- delete old queue code
- delete old databases
- change study behavior
- change companion behavior

## Next stage

Stage 5F-26 should add frontend queued-chat polling/status UI planning or a guarded UI smoke.

Production queued chat should remain disabled unless explicitly enabled.
