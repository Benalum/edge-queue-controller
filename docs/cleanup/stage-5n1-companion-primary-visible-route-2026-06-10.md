# Stage 5N-1 Companion Primary Visible Route — 2026-06-10

## Result

Made Companion the primary visible AI surface while keeping /chat working as a compatibility route.

## Changes

- Changed the top navigation AI link from Chat to Companion.
- Pointed the visible AI navigation link to /companion.
- Updated the home card from Chat to Companion.
- Updated /chat copy to describe it as a compatibility route.
- Updated /companion copy to describe it as the main AI surface.
- Rendered the existing queued AI page for both /chat and /companion.
- Updated visible queued-chat wording to Companion wording without changing backend queue behavior.
- Bumped app.js from v=20260610225000 to v=20260610231500.

## Smoke

- Local /chat returned 200 quickly.
- Public /chat returned 200 quickly.
- Local /companion returned 200 quickly.
- Public /companion returned 200 quickly.
- Local /api/system/public-status returned 200 quickly.
- Public /api/system/public-status returned 200 quickly.

## Boundary

This stage does not change backend queue/controller behavior.
This stage does not add the Companion study state machine yet.
This stage keeps /chat as a compatibility alias.
