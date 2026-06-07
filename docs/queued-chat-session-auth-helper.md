# Queued Chat Session Auth Helper — Stage 5F-16

## Purpose

Stage 5F-16 adds a disabled-by-default session-auth resolver helper for future real-user queued chat.

This stage does not change production chat behavior.

## Helper

- edge_modules/chat_queue_session_auth.py

## What the helper proves

The helper proves:

- session-auth resolver is disabled by default
- missing session token is refused
- unknown session token is refused
- expired session is refused
- revoked session is refused
- inactive user is refused
- valid session resolves authenticated_user_id server-side
- client-provided user_id is refused

## Required flag

The helper only works when:

- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1

This flag is separate from:

- LAPTOP_CHAT_QUEUE_ENABLED
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY

## Safety

This helper is not wired into production routes.

This helper does not create jobs.

This helper does not persist messages.

This helper does not call CT101.

This helper does not call Ollama.

## Future route rule

Future real-user queued chat routes must derive authenticated_user_id from this resolver or from an equivalent existing controller session resolver.

Future real-user queued chat routes must not trust user_id from request JSON.

Future real-user queued chat routes must not trust X-Synthetic-User-Id in real-user mode.

## What this stage does not do

This stage does not:

- enable real-user queued chat
- wire real-user route job creation
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

Stage 5F-17 should add a route-level smoke proving real-user mode still refuses until the session-auth resolver is explicitly wired into the route.

Production queued chat should remain disabled unless explicitly enabled.
