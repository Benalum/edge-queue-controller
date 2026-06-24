# Stage 16 FC-O45-C-C — Study Wrapper Signed-In Repair Source Patch

Date: 2026-06-24  
Scope: repo source patch only. No live VM200 deployment, no backend mutation, no DB write, no worker/model runtime.

## What changed

Patched tracked wrapper source:

`frontend/wrapper-ui/app.js`

The patch adds marker:

`APC_STUDY_SIGNED_IN_REPAIR_FC_O45_C_C`

## Purpose

The signed-in Study page was showing the durable Study session panel and then rendering an older duplicate Study block underneath it. The signed-in page also lacked visible Decks, Cards, Stats, and Review Queue modules.

This patch adds a guarded browser-side repair module that:

- Skips signed-out users by checking `/api/me`.
- Keeps the durable Study session and deck selector UI.
- Hides the duplicated legacy Study block when it is embedded under the signed-in Study surface.
- Adds a signed-in `Study tools` panel with:
  - Decks
  - Cards
  - Stats
  - Review queue
- Uses existing Study APIs:
  - `/api/study/decks`
  - `/api/study/progress`
  - `/api/study/decks/{deck_id}/cards`
  - `/api/study/decks/{deck_id}/review-queue`
- Shows honest unavailable states if an endpoint returns an error.
- Leaves durable session controls as the active review/session controls.

## Guardrails

- No live deploy in this checkpoint.
- No VM200 file mutation.
- No CT203 backend mutation.
- No DB writes.
- No job/queue/worker/model changes.
- No fake Study data.
- Signed-out Study remains public-safe.
