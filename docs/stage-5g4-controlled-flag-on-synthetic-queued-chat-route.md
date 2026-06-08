# Stage 5G-4 — Controlled flag-on synthetic queued-chat route smoke

## Goal

Prove the laptop controller queued-chat route works in a controlled flag-on synthetic-only smoke.

## Why synthetic-only first

This stage does not wire live browser submit and does not use real frontend identity.
It proves the laptop controller can create a queued chat job and read its status when explicitly enabled for a temporary test.

## Flags used only by the smoke

- LAPTOP_CHAT_QUEUE_ENABLED=1
- LAPTOP_CHAT_QUEUE_SYNTHETIC_ONLY=1

## Safety

- Queued chat remains disabled by default.
- Frontend queued chat remains disabled by default.
- app.js still must not send user_id, authenticated_user_id, or X-Synthetic-User-Id.
- This stage does not wire live submit.
- This stage does not create duplicate frontend placeholders, polling loops, or final assistant messages.
- This stage does not require CT101/PVESO lifecycle completion.
