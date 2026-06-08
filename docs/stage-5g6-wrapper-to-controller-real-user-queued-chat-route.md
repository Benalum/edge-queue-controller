# Stage 5G-6 — Controlled wrapper-to-controller real-user queued-chat route

## Goal

Prove the laptop wrapper can forward real-user queued-chat browser API requests to the laptop controller.

## What this proves

- Browser-style path /api/chat/queued is owned by the laptop wrapper.
- The wrapper forwards POST /api/chat/queued to the laptop controller.
- The wrapper forwards GET /api/chat/queued/{job_id} to the laptop controller.
- The controller session-auth real-user route creates a queued job.
- The controller status route enforces ownership.
- Frontend queued chat remains disabled by default.
- Live browser submit is still not wired.

## Safety

This stage does not enable queued chat by default.
This stage does not wire live browser submit.
This stage does not add user_id, authenticated_user_id, or X-Synthetic-User-Id to app.js.
This stage does not create frontend placeholders, polling loops, or final assistant messages.
This stage does not perform Cloudflare/public cutover.
