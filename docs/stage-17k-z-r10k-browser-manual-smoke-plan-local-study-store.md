# Stage 17K-Z-R10K — Browser Manual Smoke Plan for Local Study Store

This checkpoint prepares the manual browser smoke for the live local-only Study cutover.

## Goal

Verify in a real signed-in browser that Study uses browser-local storage and no longer calls private study server persistence endpoints.

## Manual browser steps

1. Open `https://buddieswhostudy.com/`.
2. Sign in normally.
3. Open DevTools Console.
4. Open Study.
5. Paste the generated DevTools verifier from:
   - `docs/smoke/generated/stage-17k-z-r10k-browser-manual-smoke-plan-local-study-store/devtools-study-local-smoke-verifier.<timestamp>.js`
6. Create a small test deck.
7. Create a test card in that deck.
8. Edit the test card.
9. Mark/review the card once if the UI allows it.
10. Refresh the page.
11. Confirm the deck/card still appear.
12. Run this in DevTools Console:

       await window.__APC_R10K_REPORT__()

## Pass conditions

The DevTools report should show:

- `privateStudyFetchCount: 0`
- `studyStoreAvailable: true`
- `studyStoreMode: "browser-local-only"`
- `localSaveAvailable: true`
- deck/card counts reflect the manual test
- `pass: true`

## Network tab check

In DevTools Network, filter for:

    /api/study

Expected:

- no private persistence calls
- no `/api/study/decks`
- no `/api/study/cards-lite`
- no `/api/study/progress`
- no `/api/study/review-summary-lite`
- no `/api/study/sessions-lite`
- no writeback-lite calls

The only study route intentionally left server-side for separate review is:

- `/api/study/intent/parse`

## Current live read-only smoke

This checkpoint also performs public read-only smoke to confirm:

- root is 200
- `/api/system/status` is 200
- `/api/me` is 401 signed out
- signup is 403 closed beta
- removed private study endpoints return 404
- static `study-store.js` is live and has zero `/api/study` references
- static `local-save-store.js` is live
