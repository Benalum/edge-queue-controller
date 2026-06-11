# Stage 5M-1 Companion UI and Route Audit — 2026-06-10

## Purpose

Audit the current /companion page and Companion API routes after queued Chat became functional.

## Known-good foundation

- Visible /chat now posts to /api/chat/queued.
- CT101 queue worker is active and enabled.
- Queued Chat visible UI smoke rendered: visible chat ui ok.

## This stage is audit-only

No source behavior changes were made by this stage.

## Next decision

If /companion is only a static compatibility page, either redirect /companion into /chat with companion mode or add a minimal companion panel using the same queue pattern.
