# Stage 5H-4 — Companion Browser Queued Completion Regression

## Purpose

Stage 5H-4 allows companion browser submit to use the same queued submit/poll/render path as the proven normal chat path when queued chat is explicitly enabled.

The runtime frontend source for this stage lives in CT101:

- `/opt/ai-platform/frontend/components/ChatPage.tsx`

The laptop repo owns the stage documentation and smoke verification.

## What changed

CT101 `ChatPage.tsx` no longer blocks companion queued mode with:

- `!isCompanion && useQueuedChat`

The companion page can now use the same queued browser path when the existing queued-chat flag is explicitly enabled:

1. submit to `/api/backend/chats/{chat_id}/messages/queued`
2. poll `/api/backend/chats/{chat_id}/messages/jobs/{job_id}`
3. wait for `status = complete`
4. render returned `assistant_message.content`
5. avoid page refresh for final companion text

## What did not change

- Queued chat is not globally default-on.
- Worker concurrency remains unchanged.
- The browser must not send client-provided `user_id`.
- Existing wrapper/controller trusted identity checks remain required.
- Existing Stage 5G and Stage 5H smokes must keep passing.

## Validation

The Stage 5H-4 smoke verifies the real CT101 frontend file remotely and confirms:

- Stage 5H-4 marker is present.
- `queuedChatEnabled` uses the existing `useQueuedChat` flag.
- The old `!isCompanion && useQueuedChat` blocker is absent.
- Queued create/status routes are present.
- `assistant_message` render handling is present.
- No client-provided `user_id` / `userId` is sent from the patched frontend file.
