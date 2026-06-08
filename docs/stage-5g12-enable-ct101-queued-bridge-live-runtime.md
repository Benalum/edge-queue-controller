# Stage 5G-12 — Enable CT101 queued bridge in live laptop runtime

## Goal

Enable the CT101 ChatPage queued bridge in the live laptop wrapper runtime after Stage 5G-11 lifecycle readiness passed.

## Runtime flags

Controller runtime needs:

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1
- LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED=1

Wrapper runtime needs:

- WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1

Frontend wrapper config remains:

- AI_PLATFORM_QUEUED_CHAT_ENABLED=false

## Safety

- Does not enable wrapper app.js queued submit.
- Does not wire authForm.
- Does not modify CT101 frontend.
- Bridge can be rolled back by removing WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1 and restarting wrapper.
- Controller queued chat can be rolled back by removing LAPTOP_CHAT_QUEUE_ENABLED and restarting controller.
