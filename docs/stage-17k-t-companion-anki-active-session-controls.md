# Stage 17K-T — Companion Anki Active Session Controls

Date: 2026-06-28

## Summary

Stage 17K-T lets the read-only Anki session controls mount on the Companion route.

This allows the user to re-select the local Anki file, load the selected deck into browser memory, and let Companion report the active session shape.

## Goal

After a user loads a selected Anki deck into browser memory, Companion can report:

- `active: true`
- `cards in memory: > 0`
- current card shape only
- no question text
- no answer text
- no backend calls
- no model calls
- no Anki writes

## Source changes

- `anki-readonly-session.js` now recognizes the Companion route.
- `renderPanel()` no longer exits on Companion.
- Companion route mount falls back to `#apc-companion-local-anki-bridge`, `main`, or `document.body`.
- `index.html` cache-busts the Anki read-only session adapter.

## Privacy boundary

Anki question and answer text remain in the read-only Anki session UI only.

The Companion bridge reports only status, counters, and shape.

This patch does not save Anki card text to localStorage.

This patch does not send Anki card text to the backend.

This patch does not call a model.

This patch does not write to Anki.

This patch does not write Anki-sourced cards into MyDecks.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
