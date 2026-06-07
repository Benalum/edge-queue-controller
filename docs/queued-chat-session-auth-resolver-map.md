# Queued Chat Session Auth Resolver Candidate Map — Stage 5F-15

## Purpose

Stage 5F-15 maps the exact session-auth resolver requirements before real-user queued chat is wired.

This stage is inspection and planning only.

No production chat behavior changes happen in this stage.

## Inputs

- docs/queued-chat-session-auth-resolver-inspection.md
- docs/session-derived-user-ownership-map.md
- docs/real-user-queued-chat-route-guard-placeholder.md
- edge_controller.py

## Required resolver behavior

The future real-user queued chat route must use an existing controller session/auth resolver or a tiny wrapper around it.

The resolver must:

1. read the authenticated session from the same source as the existing wrapper routes
2. derive authenticated_user_id server-side
3. reject anonymous requests
4. reject expired sessions
5. reject revoked sessions
6. never trust client-provided user_id
7. never trust X-Synthetic-User-Id in real-user mode

## Route wiring rule

The queued chat route must remain disabled by default.

Real-user queued chat must require:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1

Synthetic mode must remain separate:

- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1

## Real-user mode behavior target

When real-user queued chat is eventually wired:

- POST /api/chat/queued derives authenticated_user_id from session
- POST /api/chat/queued refuses user_id in JSON
- POST /api/chat/queued verifies chat ownership before reuse
- GET /api/chat/queued/{job_id} verifies job ownership before returning status
- assistant persistence verifies job and chat ownership before creating a message

## Current placeholder rule

Until the resolver is wired, real-user mode must continue returning:

- session_auth_not_wired_stage_5f14

## Required future smokes

Before enabling real-user queued chat:

- unauthenticated real-user POST returns 401 or 403
- expired session refused
- revoked session refused
- client-provided user_id refused
- wrong-user chat_id refused
- wrong-user job_id refused
- owned chat accepted
- owned job status accepted
- synthetic-only mode still works
- feature disabled mode still returns feature_disabled

## Recommended Stage 5F-16

Stage 5F-16 should add a disabled helper that wraps the existing session/auth resolver and returns authenticated_user_id.

Stage 5F-16 should still not create real production queued chat jobs.

## Cleanup requirement

Cleanup must wait until laptop queue is production source of truth and rollback is safe.

## Stage 5F-15 constraints

Do not:

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
