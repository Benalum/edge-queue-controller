# Stage 17K-Q — Companion Local Anki Current Card Shape Command

Date: 2026-06-28

## Summary

Stage 17K-Q adds a local-only Companion bridge command for the current Anki card shape.

The command is exposed through:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.currentCardShapeCommand()`

It returns a safe message and shape object for the current local Anki card.

It does not return Anki question text.

It does not return Anki answer text.

It does not call the backend.

It does not call a model.

It does not write to Anki.

## UI behavior

The Companion local Anki bridge panel now includes:

- `Describe current local Anki card shape`

The displayed command output includes only status, deck, counters, shape booleans, note type, and privacy copy.

## Privacy boundary

Allowed:

- source type
- active true/false
- deck name
- cards in memory count
- question present true/false
- answer present true/false
- note type
- question length
- answer length
- local counters

Forbidden:

- question text
- answer text
- Anki card ID
- Anki note ID
- media data
- backend calls
- model calls
- Anki writes
- MyDecks writeback for Anki cards

## Safety

This is a source-only stage.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
