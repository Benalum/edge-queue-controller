# Stage 5G-13 — Live browser queued-chat validation

## Goal

Validate the real active /chat page can create a laptop-owned queued chat job through the live wrapper bridge.

## What this proves

- The active CT101 ChatPage queued submit path is working through the laptop wrapper.
- POST /api/backend/chats/{chat_id}/messages/queued reaches the laptop controller.
- The laptop controller creates exactly one queued app_jobs row for the browser prompt.
- The wrapper app.js queued flag remains disabled by default.
- The wrapper bridge is enabled in runtime only.
- No duplicate assistant messages are created by the wrapper.

## Important note

This stage validates browser-to-laptop job creation. It does not assume the persistent CT101 worker is already polling the laptop queue.
If the browser UI stays waiting after the job is created, that means the next stage is enabling the CT101 worker runtime to poll the laptop queue.

## Manual browser step

1. Open the live /chat page through the laptop wrapper.
2. Turn queued chat ON in the CT101 ChatPage UI.
3. Send the exact prompt printed by the smoke.
4. Return to the terminal and let the smoke detect the laptop job.

## Safety

- Does not change code paths.
- Does not enable wrapper app.js queued submit.
- Does not change AI_PLATFORM_QUEUED_CHAT_ENABLED.
- Does not modify CT101 frontend.
- Does not enable persistent CT101 laptop-queue worker.
