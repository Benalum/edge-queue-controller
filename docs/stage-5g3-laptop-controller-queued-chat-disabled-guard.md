# Stage 5G-3 — Laptop controller queued-chat disabled guard

## Goal

Prove the laptop controller owns the queued-chat route and that queued chat remains disabled by default.

## What this proves

- edge_controller.app registers:
  - POST /api/chat/queued
  - GET /api/chat/queued/{job_id}
- A fresh controller process reaches the queued-chat route.
- The route returns the feature-disabled guard instead of generic Not Found.
- Queued chat remains safely off by default.

## Safety

This stage does not enable queued chat.
This stage does not wire live browser submit.
This stage does not create queued jobs.
This stage does not create assistant placeholders.
This stage does not start polling loops.
This stage does not send client-provided user_id, authenticated_user_id, or X-Synthetic-User-Id.
