# Stage 5N-9 Companion Route/API Inspection — 2026-06-11

## Result

Companion route/API inspection passed.

## Checkpoint before inspection

- Commit: `461b7c3`
- Tag: `controller-stage-5n8-profile-route-api-inspection-2026-06-11`

## Confirmed

The Companion page loads successfully:

- Local `/companion`: `200`
- Public `/companion`: `200`

The active Companion UI is wrapper-native queued chat.

The `/chat` and `/companion` routes both render:

- `renderQueuedChatPage()`
- `bindQueuedChatPage()`

The active Companion send path is:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

The wrapper maps queued chat directly to the laptop controller:

- `/api/chat/queued`
- `/api/chat/queued/{job_id}`

The wrapper bridges the browser session cookie into the controller-only queued-chat session header:

- `X-Queued-Chat-Session-Token`

The wrapper also injects trusted identity headers for direct queued-chat calls when the trusted proxy secret is available:

- `X-Edge-Auth-Secret`
- `X-Edge-User-Id`
- `X-Edge-User-Email`
- `X-Edge-User-Is-Admin`

Unauthenticated queued chat correctly returns `401`.

## Compatibility routes still present

The controller still has older/direct Companion routes:

- `POST /api/companion/study/grade`
- `GET /api/companion/context`
- `POST /api/companion/chat`

These should not be deleted yet.

They may still be useful for:

- Companion context
- Future Study session integration
- Direct internal compatibility
- Study answer grading

## Decision

Do not delete direct Companion routes yet.

Keep the user-facing `/companion` page on the queued path:

- `/api/chat/queued`

Treat `/api/companion/*` as compatibility/context/study helper routes until the Study-session Companion design is implemented.

## Notes

Stage 5N-9 does not change runtime behavior.

Stage 5N-9 records that Companion is already using the smooth queued path for the main user-facing chat surface.
