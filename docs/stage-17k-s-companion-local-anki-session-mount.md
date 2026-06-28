# Stage 17K-S — Companion Local Anki Session Mount

Date: 2026-06-28

## Summary

Stage 17K-S adds a Companion-side local-only mount command for the existing Anki read-only session adapter.

The mount command is exposed through:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.ankiSessionMountCommand()`

The command calls the existing browser-local adapter:

- `window.APC_ANKI_READONLY_SESSION.renderPanel()`

This keeps Anki study separate from MyDecks.

## User-facing behavior

The Companion local Anki bridge panel now includes:

- `Mount local Anki session controls`

The mount output reports only adapter/session status and aggregate counters.

It does not return Anki question text.

It does not return Anki answer text.

## Source separation

Anki remains separate from APC / Local / MyDecks cards.

This stage does not patch `companion.js` MyDecks command handlers.

This stage does not route Anki cards through MyDecks create/edit/delete/flag/write flows.

This stage does not merge Anki cards into `APC_STUDY_STORE`.

## Privacy boundary

Allowed through the mount command:

- adapter present true/false
- adapter rendered true/false
- source type
- status
- active true/false
- selected deck name
- selected deck id
- cards in memory count
- reviewed count
- correct count
- wrong count
- current index

Forbidden through the mount command:

- raw question text
- raw answer text
- card id
- note id
- media filenames
- media data
- tags
- backend calls containing Anki card content
- model calls containing Anki card content
- Anki writes
- MyDecks writeback for Anki cards

## Safety

This is a static frontend source stage.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
