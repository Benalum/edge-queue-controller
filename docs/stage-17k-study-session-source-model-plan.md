# Stage 17K — Study Session Source Model Plan

Date: 2026-06-28

## Summary

After Stage 17J-R4C, the Profile page has a clean browser-local Anki file picker/proof flow. The next Study/Companion direction is to expose Study Sessions with explicit deck source choices:

1. Study Session with Anki
2. Study Session with My Decks

This keeps imported/read-only Anki content separate from APC-native decks while preserving a path toward user-owned Google Drive storage.

## Current inventory

Frontend inventory found no browser SQLite or WASM parser under `frontend/`.

The current Anki panel supports:

- User-selected file picker
- Browser-local proof
- Header detection
- Sample SHA-256
- No upload
- No backend save
- No DB write
- No Anki write

## Product model

### Study Session with Anki

Use when the user wants to study from an existing Anki source.

Supported file sources should eventually include:

- `collection.anki2`
- `collection.anki21`
- `.apkg`
- `.colpkg`

Initial behavior:

- User explicitly selects the file.
- APC reads it browser-locally.
- APC extracts deck/card metadata read-only.
- User chooses which decks to study.
- APC does not write back to Anki.

Later behavior:

- Optionally import selected cards into APC-native My Decks.
- Preserve original Anki source metadata.
- Keep import actions explicit and reversible.

### Study Session with My Decks

Use when the user wants APC-native decks.

My Decks should support:

- User-created cards
- AI-generated cards
- Imported cards from Anki
- Edited cards
- Deleted/archive cards
- Study history
- Session progress
- Speaking/listening practice metadata

Initial storage can remain APC platform storage.

Long-term storage direction:

- Link My Decks with the user's Google Drive.
- Store deck data in the user's own Google account.
- Keep platform metadata minimal.
- Make sync opt-in and user-visible.

## Companion integration

When returning to Companion, Study should expose source-aware session creation:

- “Start Study Session with Anki”
- “Start Study Session with My Decks”

Companion should know which source is active so it can:

- Tutor from selected decks
- Generate explanations
- Ask quiz questions
- Produce flashcards
- Support speaking/listening sessions
- Track session state without confusing Anki-read-only cards and APC-native cards

## Recommended implementation order

### Stage 17K-A — Source model docs/checkpoint

Record this Study Session source model.

No frontend deploy.

### Stage 17K-B — Local Anki deck extraction proof

Use local Python against a selected `collection.anki2` to prove:

- Deck names
- Card counts
- Note counts
- Note type names

No browser parser yet.

### Stage 17K-C — Browser SQLite parser decision

Choose a pinned browser SQLite parser or WASM dependency intentionally.

No CDN dependency for production.

### Stage 17K-D — Browser-local Anki metadata extraction

Parse selected Anki files in the browser.

No upload and no backend save.

### Stage 17K-E — Study source picker UI

Add UI choices:

- Study with Anki
- Study with My Decks

### Stage 17L — Google Drive My Decks plan

Design opt-in Drive sync for APC-native My Decks.

## Safety constraints

Do not perform any of the following without a separate approval:

- Backend deploy
- DB migration
- Google OAuth change
- Google Drive write
- Anki file write
- Full Anki file upload
- Worker/model activation
- Scheduler activation
- Service restart
