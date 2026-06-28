# Stage 17K-S-R3 — Anki Readonly renderPanel Export

Date: 2026-06-28

## Summary

Stage 17K-S-R3 repairs the actual Companion-to-Anki adapter mount path.

Stage 17K-S-R2 proved the Companion mount output existed, but browser proof still showed:

- `mounted: false`
- `adapter present: yes`
- `adapter rendered: no`

Preflight confirmed that `window.APC_ANKI_READONLY_SESSION` existed but did not export `renderPanel`.

This patch exports:

- `renderPanel: renderPanel`

from the Anki read-only session adapter.

## Scope

Static frontend source only:

- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js`

## Privacy boundary

This patch does not change Anki card extraction behavior.

This patch does not return Anki question text through the Companion bridge.

This patch does not return Anki answer text through the Companion bridge.

This patch does not add backend calls.

This patch does not add model calls.

This patch does not add Anki writes.

This patch does not add MyDecks writeback for Anki-sourced cards.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
