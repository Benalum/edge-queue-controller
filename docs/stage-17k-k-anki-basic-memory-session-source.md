# Stage 17K-K — Anki Basic Memory Session Source Patch

Date: 2026-06-28

## Summary

Stage 17K-K upgrades the Anki read-only session adapter from a skeleton to a browser-local Basic card memory session.

It can load cards from the selected Anki deck into JavaScript memory only.

## Behavior

The adapter:

- reads selected source from `apc.study.sourceSelection.v1`
- requires `source_type: anki_browser_local`
- requires the user to re-select the Anki SQLite file
- loads same-origin vendored sql.js
- filters cards by selected Anki deck ID
- joins `cards` to `notes`
- splits `notes.flds` on the Anki field separator
- maps `Front` to question
- maps `Back` to answer
- shows question and answer locally
- supports reveal/right/wrong/stop locally
- clears in-memory cards on stop

## Privacy

Card text is held in JavaScript memory only for the active browser page.

Card text is not saved to localStorage.

Card text is not sent to the backend.

The adapter does not call `/api/study/*`.

The adapter does not use MyDecks writeback.

The adapter does not write to Anki.

## Safety

This source patch does not deploy frontend code.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
