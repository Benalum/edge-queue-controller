# Stage 5G-16 — Pre-auth trusted CT101 mirror refresh

## Goal

Fix stale mirrored CT101 session/chat ownership before laptop queued-chat ownership checks.

## Why

Stage 5G-15 showed the browser is correctly sending:

POST /api/backend/chats/{chat_id}/messages/queued

but one request failed with:

chat does not belong to authenticated user

The cause is stale mirrored laptop state: once a CT101 token has an app_sessions row, the controller resolves it before refreshing the trusted CT101 mirror.

## Fix

When trusted X-Edge-* headers are present and EDGE_TRUSTED_PROXY_SECRET matches, the controller refreshes:

- mirrored CT101 user
- mirrored CT101 session
- mirrored CT101 chat ownership

before resolving the session and before the real-user queued-job helper checks ownership.

## Safety

- Does not trust client-provided user_id.
- Still requires EDGE_TRUSTED_PROXY_SECRET.
- Still keeps app.js free of user_id, authenticated_user_id, and X-Synthetic-User-Id.
- Does not enable wrapper app.js queued submit.
