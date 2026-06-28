# Stage 16 Global Drive Banner R3P

This checkpoint corrects R3O banner placement.

## Correction

R3O added the data ownership notice inside the Companion tab. The intended placement is a site-wide banner above the page header so it appears across the wrapper app, not only inside Companion.

## Behavior

- Removes the Companion-tab Data ownership notice section.
- Adds a global banner in `index.html` immediately after the opening `body` tag.
- Banner text:

> Data ownership update: We’re working toward Google Drive sync so decks, cards, sessions, and study history can stay in each user’s own Google account. Current storage remains on the existing platform until Drive sync is built, tested, and enabled.

## Scope

- Static repo mirror correction:
  - `frontend/wrapper-ui/apc-wrapper-local/index.html`
  - `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js`
- VM200 static file deploy only.
- Keeps the R3O local-first Google Drive architecture plan.

No backend changes, no DB writes, no service restarts, no CT/VM restart, no OAuth work, no Google API integration, and no model/runtime/scheduler mutation.
