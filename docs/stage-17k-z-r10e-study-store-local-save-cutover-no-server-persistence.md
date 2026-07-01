# Stage 17K-Z-R10E — Study Store Local Save Cutover

This stage removes the frontend study store dependency on private server persistence endpoints.

## What changed

`frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js` now runs in browser-local-only mode for private study data.

It no longer calls private `/api/study/*` persistence endpoints for:

- deck reads
- card reads
- progress reads
- review summary reads
- session reads
- deck writeback
- card writeback
- session writeback

## Local storage model

The current UI still expects synchronous study-store methods. To avoid breaking the UI, R10E keeps localStorage as a short-term working cache and mirrors the same state into `window.APC_LOCAL_SAVE`.

Durable local save target:

- `APC_LOCAL_SAVE`
- IndexedDB database: `buddies_who_study_local_v1`

Mirrored document keys:

- `study/store-state/v1`
- `study/decks/v1`
- `study/cards/v1`
- `study/sessions/v1`
- `study/progress/v1`

Review actions also call `APC_LOCAL_SAVE.recordCardReview()` so progress can be tracked as compact events plus rollups.

## Why this is transitional

The final target is to remove reliance on localStorage for private study content and use IndexedDB as the direct authority. R10E keeps localStorage only to preserve the current synchronous UI contract while server persistence is removed.

## Backend policy

No backend endpoints were removed in this stage.

The next backend removal stages should delete private study persistence routes after the frontend no longer depends on them.

Final backend removal should be real deletion, not wrapper-only blocking.
