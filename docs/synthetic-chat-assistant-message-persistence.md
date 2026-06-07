# Synthetic Chat Assistant Message Persistence — Stage 5F-5

## Purpose

Stage 5F-5 adds a synthetic helper and smoke for queued chat assistant-message persistence.

This stage does not change production chat behavior.

## Helper

- edge_modules/chat_queue_persistence.py

## What the helper proves

The helper proves:

- a completed queued chat job creates one assistant message
- duplicate persistence returns the same assistant message
- failed jobs do not create assistant messages
- wrong-user jobs cannot create assistant messages
- app_messages.source_job_id enforces idempotency

## Safety

This helper is not wired into production routes.

It is used only by synthetic smoke tests in this stage.

## What this stage does not do

This stage does not:

- change production chat behavior
- add production queued chat routes
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

Stage 5F-6 should add an opt-in queued chat route plan or an implementation behind a disabled feature flag.

Production behavior should remain unchanged unless explicitly enabled.
