# Stage 5G-2 — Laptop wrapper queued-chat route ownership bridge

## Goal

Make the laptop wrapper explicitly route queued-chat browser API calls to the laptop controller.

## Why

Before this stage, unknown /api/* paths could fall through to the public gateway.
The future frontend queued-chat helper uses /api/chat/queued, so this path must be
owned by the laptop controller before any live submit wiring is enabled.

## Route ownership

- /api/chat/queued -> laptop controller /api/chat/queued
- /api/chat/queued/{job_id} -> laptop controller /api/chat/queued/{job_id}
- /api/backend/* remains CT101 FastAPI.
- /api/study/* and /api/companion/* remain public gateway bridges.
- queued chat remains disabled by default.

## Safety

This stage does not wire live submit.
This stage does not enable queued chat by default.
This stage does not send user_id, authenticated_user_id, or X-Synthetic-User-Id from app.js.
This stage does not create jobs, placeholders, polling loops, or final assistant messages.
