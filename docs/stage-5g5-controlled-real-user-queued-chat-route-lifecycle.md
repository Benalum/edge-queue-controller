# Stage 5G-5 — Controlled real-user queued-chat route lifecycle

## Goal

Prove the laptop controller real-user queued-chat route lifecycle works under controlled smoke conditions.

## What this proves

- Real-user queued-chat guard helper works.
- Real-user queued-chat route creation works.
- Real-user queued-chat status route ownership works.
- Previous synthetic-only and disabled-guard checks still pass.
- Frontend queued chat remains disabled by default.
- Browser live submit is still not wired.

## Safety

This stage does not enable queued chat by default.
This stage does not wire live browser submit.
This stage does not send user_id, authenticated_user_id, or X-Synthetic-User-Id from app.js.
This stage does not create duplicate frontend placeholders, polling loops, or final assistant messages.
This stage does not perform Cloudflare/public cutover.
