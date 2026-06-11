# Stage 5O-35 Companion Visual UX Redesign

## Purpose

Stage 5O-35 polishes the logged-in Companion page into a two-column app-style workspace while preserving the existing queued chat backend flow.

## Scope

- Frontend-only Companion UI enhancer.
- Keeps `/api/chat/queued` and `/api/chat/queued/{job_id}` behavior unchanged.
- Adds a conversation workspace shell, status cards, last-job display, model/worker placeholders, explanation card, and UI-only Study context placeholder.
- Does not add backend routes.
- Does not add a local calendar database.
- Does not change header/auth behavior.

## Verification

- `node --check frontend/wrapper-ui/app.js`
- Local wrapper route smoke for Companion, Chat, Profile, Study, Support, Credits, Admin, and System.
- Recent journal review for traceback/error signals.
