# Stage 5G-7 — Browser-cookie frontend queued-chat helper through wrapper

## Goal

Prove the frontend queued-chat helper can call the laptop wrapper/controller path using browser-style cookie auth.

## What this proves

- app.js send helper calls /api/chat/queued.
- app.js status helper calls /api/chat/queued/{job_id}.
- The helper uses credentials: include.
- The helper does not send user_id, authenticated_user_id, X-Synthetic-User-Id, or X-Queued-Chat-Session-Token.
- The wrapper converts edgeStudyToken cookie to X-Queued-Chat-Session-Token server-side for /api/chat/queued.
- The laptop controller creates a real-user queued job and returns owned status.
- Frontend queued chat remains disabled by default.
- Live submit remains unwired.

## Safety

This stage does not enable queued chat by default.
This stage does not wire live browser submit.
This stage does not create frontend placeholders, polling loops, or final assistant messages.
This stage does not perform Cloudflare/public cutover.
