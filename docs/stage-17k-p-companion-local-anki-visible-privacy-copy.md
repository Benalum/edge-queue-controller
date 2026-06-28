# Stage 17K-P — Companion Local Anki Visible Privacy Copy

Date: 2026-06-28

## Summary

Stage 17K-P repairs the Companion local Anki bridge panel copy.

Stage 17K-O proved the Companion panel was present and safe, but `panelTextHasPrivacyCopy` was false because the card-text privacy copy was not visible in the primary panel text.

This source patch makes the privacy line visible without opening details:

- `This bridge does not return card question text or answer text.`

## Scope

Static frontend source only:

- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js`

## Privacy boundary

The bridge still returns only shape/status/counter information.

The bridge does not return Anki question text.

The bridge does not return Anki answer text.

The bridge does not allow backend calls.

The bridge does not allow model calls.

The bridge does not allow Anki writes.

The bridge does not allow MyDecks writeback for Anki-sourced cards.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
