# Stage 5G-9 — CT101 ChatPage queued bridge to laptop controller

## Goal

Bridge the active CT101 ChatPage queued-chat API shape through the laptop wrapper to the laptop controller.

## Why

The active /chat UI is currently CT101-owned. It calls:

- POST /api/backend/chats/{chat_id}/messages/queued with { content, model }
- GET /api/backend/chats/{chat_id}/messages/jobs/{job_id}

The laptop controller owns:

- POST /api/chat/queued with { message, chat_id, requested_model }
- GET /api/chat/queued/{job_id}

## Safety

- Bridge is disabled by default.
- Enable only with WRAPPER_QUEUED_CHAT_BRIDGE_ENABLED=1.
- Does not modify CT101 frontend.
- Does not modify wrapper app.js live submit.
- Does not enable AI_PLATFORM_QUEUED_CHAT_ENABLED by default.
- Does not send client user_id/authenticated_user_id/X-Synthetic-User-Id.
- Does not materialize assistant messages yet.
