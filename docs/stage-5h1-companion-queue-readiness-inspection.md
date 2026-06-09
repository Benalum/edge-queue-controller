# Stage 5H-1 — Companion Queue Readiness Inspection

## Purpose

Stage 5H-1 inspected the current companion chat request path before changing runtime behavior.

No runtime code is changed in this stage.

No queued chat default is changed in this stage.

No worker concurrency is changed in this stage.

No secrets, tokens, prompts, raw environment values, or user message contents are documented.

## Current known-good base

Starting checkpoint:

- HEAD: 8c239be
- Tag: controller-stage-5g30-final-queued-chat-cutover-readiness-report-2026-06-08

Previously proven:

- Stage 5G-27 proved live browser queued chat works end-to-end.
- Stage 5G-28 proved runtime invariants.
- Stage 5G-29 proved restart persistence.
- Stage 5G-30 documented queued-chat cutover readiness.

## Inspection findings

### 1. CT101 companion and chat share core chat storage

CT101 uses the shared chat/message model for both normal chat and companion mode.

The inspected CT101 backend showed:

- `chats`
- `messages`
- companion-specific support tables, including companion profile/study session state

Companion mode is not a separate message table. It is a mode of the shared chat system.

### 2. CT101 backend currently blocks queued companion directly

The CT101 queued route exists at:

- `POST /api/chats/{chat_id}/messages/queued`
- `GET /api/chats/{chat_id}/messages/jobs/{job_id}`

The CT101 route currently rejects non-normal-chat mode with:

- `Queued chat is only enabled for normal chat mode in this stage.`

This means a direct CT101 backend queued request for a companion chat is intentionally blocked today.

### 3. CT101 frontend currently disables queue mode for companion

The CT101 frontend currently calculates queued mode with:

- `queuedChatEnabled = !isCompanion && useQueuedChat`

This means companion mode is forced onto the synchronous request path today.

### 4. CT101 frontend already has the smooth queued render pattern

The normal queued chat frontend path already does the right browser behavior:

1. optimistically appends the user message
2. posts to `/api/backend/chats/{chat_id}/messages/queued`
3. polls `/api/backend/chats/{chat_id}/messages/jobs/{job_id}`
4. waits for `status === "complete"` and `assistant_message`
5. appends `assistant_message.content`
6. avoids page refresh for final text rendering

This is the pattern companion should mirror.

### 5. Wrapper bridge already transforms queued jobs into CT101-compatible shape

The active wrapper bridge can intercept:

- `POST /api/backend/chats/{chat_id}/messages/queued`
- `GET /api/backend/chats/{chat_id}/messages/jobs/{job_id}`

and map them to laptop controller routes:

- `POST /api/chat/queued`
- `GET /api/chat/queued/{job_id}`

The wrapper status transform creates a CT101-compatible `assistant_message` object for completed jobs with a non-empty reply.

This is the return-message style companion should reuse.

### 6. Current wrapper bridge is URL-compatible but not companion-aware

The wrapper bridge matches the queued chat URL shape, not the CT101 chat mode.

Because the URL does not include `mode=companion`, the wrapper currently cannot tell from the route alone whether a request is normal chat or companion chat.

### 7. Laptop controller trusted CT101 mirror currently writes bridged chats as normal chat

The laptop controller trusted CT101 identity bridge mirrors CT101 chat IDs into laptop `app_chats`.

Current inspected behavior inserts mirrored chats with:

- `mode = 'chat'`
- title similar to `CT101 Chat`

This is safe for normal queued chat, but it is not enough for companion queue ownership because it loses companion mode.

### 8. Real-user queued job helper currently creates normal-chat-shaped jobs

The real-user queued creation helper currently creates:

- user `app_messages` row
- queued `app_jobs` row
- `job_type = 'ollama_chat'`
- `payload_json.mode = 'chat'`

This is proven for normal chat, but companion needs a guarded mode-preserving path.

### 9. Worker can process the needed job type without concurrency change

The managed CT101 laptop-queue worker already claims and processes `ollama_chat` jobs.

The worker also separately supports `companion_study_grade`.

Stage 5H should not increase concurrency above 1.

### 10. HTML/error sanitizer is only a temporary guard

The wrapper UI has a global sanitizer that hides raw Cloudflare/html gateway error pages.

That protects the browser display, but it is not the root fix.

The root fix is to avoid synchronous companion waits and use queued completion with a CT101-compatible final `assistant_message`.

## Stage 5H-2 recommended target

Stage 5H-2 should make the companion queued path explicit and guarded.

Recommended approach:

1. Keep normal queued chat behavior unchanged.
2. Do not make queued chat globally default-on.
3. Add a mode-safe companion queued route/data ownership path.
4. Preserve server-derived identity only.
5. Do not accept client-provided `user_id`.

Plain smoke phrase: Do not accept client-provided user_id.
6. Preserve wrapper trusted identity safety checks.
7. Preserve existing Stage 5G smokes.
8. Keep worker concurrency at 1.
9. Avoid exposing secrets, env values, prompts, or message contents in system status.
10. Ensure companion queued completion returns the same CT101-compatible `assistant_message` shape as normal queued chat.

## Key implementation concerns for Stage 5H-2

Stage 5H-2 should not simply flip `queuedChatEnabled` for companion.

Before frontend companion queue enablement, the backend/controller path must know the request is companion mode.

Otherwise, companion requests may be queued and completed as normal chat-shaped jobs.

The safe next patch should likely add one of these guarded mode propagation options:

- frontend sends a non-identity `mode: "companion"` field in the queued message payload, and the wrapper/controller validates it against trusted CT101 ownership; or
- wrapper queries/derives CT101 chat mode server-side before creating the laptop queued job; or
- CT101 backend owns companion queued creation directly and forwards only a sanitized job to the laptop queue.

The smallest staged option is probably:

- allow only `mode` values `chat` and `companion`
- never accept `user_id`
- mirror trusted CT101 chat with the declared mode
- store `payload_json.mode` as declared/validated mode
- keep `job_type = ollama_chat` for the first companion queue pass
- return the same `assistant_message` shape
- keep companion queued UI behind an explicit companion-specific guard

## Stage 5H-1 conclusion

Stage 5H-1 is inspection-only and ready to commit.

The next runtime patch should be Stage 5H-2.

