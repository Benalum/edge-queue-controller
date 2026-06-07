# Real-User Queued Chat Guard Helper — Stage 5F-13

## Purpose

Stage 5F-13 adds a disabled-by-default helper for future real-user queued chat guard validation.

This stage does not change production chat behavior.

## Helper

- edge_modules/chat_queue_real_user_guard.py

## What the helper validates

The helper validates:

- real-user queued chat requires LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- authenticated_user_id is required
- client-provided user_id is refused
- message is required
- existing chat reuse requires app_chats.user_id ownership
- queued job status requires app_jobs.user_id ownership

## Safety

This helper is not wired into production routes.

This helper does not create jobs.

This helper does not persist messages.

This helper does not call CT101.

This helper does not call Ollama.

## Required future route behavior

Future real-user queued chat routes must derive authenticated_user_id from the controller session.

Future real-user queued chat routes must not trust user_id from the client.

Future real-user queued chat routes must refuse wrong-user chat reuse and wrong-user job status lookup.

## What this stage does not do

This stage does not:

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

## Next stage

Stage 5F-14 should wire the route to this guard only in disabled/test mode or produce a real-user route implementation plan.

Production queued chat should remain disabled unless explicitly enabled.
