# Stage 5J-4 Chat Compatibility Bridge Audit — 2026-06-10

## Purpose

Audit whether Chat still depends on the `/api/backend/*` compatibility bridge or can move fully to laptop-owned `/api/chat/queued` routes.

## Result

This stage is audit-only. No compatibility code is removed.

## Things to decide from terminal output

- Does the served Chat frontend still call `/api/backend/*`?
- Does the served Chat frontend call `/api/chat/queued` directly?
- Does the wrapper CT101 compatibility bridge return a controlled 401/404/405, or a broken 502?
- Which route should be kept until the Chat UI is migrated?

## Safe cleanup rule

Do not remove `/api/backend/*` bridge code until the browser Chat submit path has been tested and confirmed to use laptop-owned `/api/chat/queued` directly.

## Observed result

- `/chat` shell returned HTTP 200.
- Direct `/api/chat/queued` exists; GET returned HTTP 405 Method Not Allowed, which is acceptable for a POST-only create route.
- Direct `/api/chat/queued/fake-job-id` returned controlled feature-disabled/not-found behavior from the controller, not a gateway failure.
- Compatibility `/api/backend/chats/test-chat/messages/jobs/fake-job-id` returned HTTP 401 Not authenticated, not HTTP 502.
- `edge-queue-public-gateway.service` remains inactive.
- Port `7071` has no listener.

## Decision

Keep `/api/backend/*` compatibility bridge code for now.

Reason: the wrapper still contains active compatibility handling for CT101 ChatPage queued paths. Removal should wait until the browser Chat submit path is fully migrated and proven to use laptop-owned `/api/chat/queued` directly.
