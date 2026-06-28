# Stage 17K-R — Companion Anki/Local Source Separation and Future Drive Sync Plan

Date: 2026-06-28

## Summary

Stage 17K-R records the design direction for Companion study source separation.

Companion must support two separate study sources:

1. APC / Local / MyDecks cards
2. User-selected Anki cards

The sources must remain separate.

Anki cards must not be merged into MyDecks.

Anki cards must not be routed through MyDecks create/edit/delete/flag/write flows.

## Desired future user flow

The user should be able to talk to Companion and choose a source:

- `Use Anki`
- `Show my Anki decks`
- `Study Anki Deck1`
- `Use Local decks`
- `Show my platform decks`
- `Start a study session`

If the user selects Anki, Companion should use the user-provided local Anki file source to read the data needed for the session.

If the user selects Local/MyDecks, Companion should use APC platform-created decks and cards.

## Anki source direction

The Anki path should support a user-provided browser-local file source.

The source may be represented by a local file picker first.

Later, the UI may allow the user to provide a local file location/path-style value where browser security allows it.

The Anki source should let Companion:

- discover deck names
- list available Anki decks
- select an Anki deck
- load selected Anki cards into browser memory
- run a study session from selected Anki cards
- reveal cards only inside the local Anki read-only session UI
- track session/card stats locally

The Anki source must remain read-only toward Anki.

## Local/MyDecks source direction

The Local/MyDecks source is for platform-created cards.

This source may support:

- create deck
- edit deck
- delete/archive deck
- create card
- edit card
- delete/archive card
- flag card
- study session
- local stats
- future Google Drive sync

These edit/write flows apply to platform cards only.

They do not apply to Anki-sourced cards.

## Session stats direction

For now, session stats should remain local.

Track locally:

- source type
- deck name
- session started time
- session duration
- reviewed count
- correct count
- wrong count
- current index
- session completion state

For Anki sessions, local stats may reference deck/session metadata and aggregate counters.

Do not persist raw Anki question text or answer text into backend, model calls, or repo docs.

## Future Google Drive direction

When Google Drive sync is implemented, APC should support push/pull of user study data.

Drive sync may include:

- user preferences
- selected source metadata
- local deck/card data for APC platform decks
- aggregate session stats
- review counters
- study history summaries

Anki and platform cards must remain separate in Drive sync.

Anki card content should not be uploaded to Drive or APC backend unless a separate explicit design approves it.

The first Drive sync design should prefer syncing stats and metadata, not raw Anki card content.

## Privacy boundary

Allowed for Anki bridge/session stats:

- source type
- deck name
- deck id where safe
- cards in memory count
- reviewed count
- correct count
- wrong count
- current index
- card present true/false
- question present true/false
- answer present true/false
- note type name
- question length
- answer length
- session duration
- aggregate study stats

Forbidden for Anki bridge/backend/model paths:

- raw question text
- raw answer text
- card id
- note id
- media filenames
- media data
- tags
- per-card transcript
- backend calls containing Anki card content
- model calls containing Anki card content
- Anki writes
- MyDecks writeback for Anki cards

## Implementation direction

Stage 17K-S should add a Companion local Anki session mount.

The mount should:

- stay separate from `companion.js` MyDecks edit/write flows
- use `APC_ANKI_READONLY_SESSION` for browser-local Anki loading/session actions
- use `APC_COMPANION_LOCAL_ANKI_BRIDGE` for safe shape/status/counter reporting
- make the source choice visible: Anki vs Local/MyDecks
- avoid backend calls
- avoid model calls
- avoid storing Anki question text or answer text
- explain that file re-selection may be required after hard refresh due to browser file security

## Safety

This is a docs/smoke-only planning stage.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
