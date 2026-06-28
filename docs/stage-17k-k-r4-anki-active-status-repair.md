# Stage 17K-K-R4 — Anki Active Status Repair

Date: 2026-06-28

## Summary

Stage 17K-K-R4 repairs the Anki Basic memory session status field after live testing.

Observed live state:

- cards were loaded and usable in browser memory
- `active: true`
- `card_count_in_memory: 2`
- reveal/right/wrong worked
- a later reload click with no selected file changed `status` to `error`
- message became `No file selected.`

The real session state was usable, but the displayed status was misleading.

## Repair

The repair moves the no-file/loaded-cards guard into `extractBasicCardsIntoMemory`.

If cards are already loaded and the user tries to load again with no selected file, the adapter now:

- preserves loaded cards
- preserves active local session state
- restores status to `active` when active
- returns a normal snapshot
- does not throw `No file selected.`

## Privacy

No card text is saved to localStorage.

No Anki content is uploaded.

No backend call is added.

No Anki write is added.

No MyDecks writeback is added.

## Deploy scope

Static frontend only:

- `index.html`
- `privatepages/anki-readonly-session.js`

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
