# Session-Derived User Ownership Map — Stage 5F-12

## Purpose

Stage 5F-12 maps how future real-user queued chat must derive user ownership from existing controller session/auth behavior.

This stage is inspection and planning only.

No production chat behavior changes happen in this stage.

## Inputs

- docs/session-derived-user-ownership-inspection.md
- docs/real-user-queued-chat-guard-plan.md
- docs/synthetic-queued-chat-route-ct101-lifecycle.md
- docs/synthetic-queued-chat-route-wiring.md
- edge_controller.py

## Required future ownership rule

Future real-user queued chat must derive user_id from the authenticated session.

The route must not trust:

- user_id in request JSON
- X-Synthetic-User-Id in real-user mode
- chat_id unless ownership is verified
- job_id unless ownership is verified

## Real-user route requirements

A future real-user queued chat route must:

1. require an authenticated session
2. derive authenticated_user_id from the session helper
3. reject anonymous requests
4. reject client-provided user_id
5. verify app_chats.user_id before reusing chat_id
6. create app_messages user row only for authenticated_user_id
7. create app_jobs row only for authenticated_user_id
8. return queued job status only if app_jobs.user_id matches authenticated_user_id
9. persist assistant messages only if app_jobs.user_id and app_chats.user_id match authenticated_user_id

## Feature flag requirement

Real-user queued chat must require all of these:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY must not be required for real-user mode

Enabling LAPTOP_CHAT_QUEUE_ENABLED alone must not allow real-user queued jobs.

## Synthetic mode separation

Synthetic mode remains test-only.

Real-user mode must not accept X-Synthetic-User-Id.

Synthetic-only route behavior must remain available for smoke tests until production migration is stable.

## Required future implementation shape

Recommended next implementation shape:

- add a small helper that resolves authenticated_user_id from existing controller auth/session behavior
- keep queued route default disabled
- when real-user flag is off, preserve current Stage 5F-9 synthetic-only behavior
- when real-user flag is on, call the session-derived user helper
- do not create queued jobs for anonymous users

## Required future smokes

Before real-user queued chat is enabled:

- unauthenticated POST refused smoke
- client-provided user_id ignored/refused smoke
- authenticated user creates queued job smoke
- wrong-user chat_id refused smoke
- wrong-user job_id status refused smoke
- failed job creates no assistant smoke
- duplicate persistence same message smoke
- rollback flag disables queued chat smoke

## Recommended Stage 5F-13

Stage 5F-13 should add a disabled-by-default real-user auth guard helper.

Stage 5F-13 should not create real production queued chat jobs yet.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5F-12 constraints

Do not:

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
