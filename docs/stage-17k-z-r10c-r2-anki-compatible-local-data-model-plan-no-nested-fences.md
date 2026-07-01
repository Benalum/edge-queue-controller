# Stage 17K-Z-R10C-R2 — Anki-Compatible Local Data Model Plan

This stage records the local-first data model for Anki-compatible studying in Buddies Who Study.

## Decision

Use a hybrid Anki-compatible local shadow library.

Buddies should be able to read/import Anki content, preserve Anki identities, and offer an Anki-like study experience while saving Buddies progress locally. The original Anki files remain read-only unless a future explicit export tool is built.

## Product modes

### 1. Study Anki Read-Only

The user selects an Anki source. Buddies reads decks, notes, cards, templates, and media for study.

Rules:

- Do not mutate the original Anki file.
- Do not upload Anki deck/card/media content to the APC server.
- Save Buddies study progress locally in IndexedDB.
- Allow progress, stats, and companion-guided study inside Buddies.

### 2. Import to Buddies Library

The user can copy Anki content into the Buddies local library.

Rules:

- Preserve source identifiers where available.
- Preserve deck paths, note type names, template names, and media names.
- Store media once by SHA-256 and reference it from cards.
- User may edit the Buddies local copy.
- Original Anki remains untouched.

### 3. Compare / Re-import

Later, the user can select the same Anki source again.

Rules:

- Calculate differences.
- Show additions, updates, deletions, and possible conflicts.
- Ask the user before applying changes.
- No automatic destructive two-way sync.

## Why not direct Anki mutation now?

Direct two-way Anki sync is risky because it must handle note edits, card template changes, deck renames, media changes, scheduling state, review history, and conflicts. A browser app should not silently mutate a user's Anki collection.

The safe path is read/import first, local progress second, explicit compare/re-import third, export later.

## Local storage authority

The browser-local IndexedDB database added in R10B remains the authority for private user content:

- buddies_who_study_local_v1

Object stores:

- docs
- events
- media

Private content should not be persisted to the APC server.

## Canonical documents

The local library uses document-style records:

- sync/manifest/v1
- profile/preferences/v1
- study/decks/v1
- study/notes/v1
- study/cards/v1
- study/note-types/v1
- study/sessions/v1
- study/progress/v1
- companion/preferences/v1
- companion/local-memory/v1

## Anki identity preservation

Imported/read Anki records should preserve:

- source import id
- Anki note GUID, when available
- Anki card id, when available
- Anki card ordinal
- deck path
- note type name
- template name
- original modified timestamp, when available
- content hash
- original media filename

These references allow later compare/re-import without touching the original Anki source.

## Smart storage

### Cards and notes

Cards and notes should store text/template fields and references, not repeated media bytes.

### Media

Media is stored separately by SHA-256 hash.

Cards reference media by hash, for example:

    mediaRefs: ["sha256..."]

This prevents the local database from growing unnecessarily with duplicate image copies.

### Progress

Progress is stored as compact review events plus rollups.

Event fields:

    eventType: card_review
    grade: again | hard | good | easy
    wasCorrect: true or false
    answerMs: number
    sessionType: standard | cramming | weak_cards | companion_guided

Rollup examples:

- progress/cards/<cardId>/v1
- progress/decks/<deckId>/v1
- progress/daily/<YYYY-MM-DD>/v1

This supports stats over time without saving full card/deck snapshots repeatedly.

## Scheduler direction

Initial scheduler:

- apc-simple-v1

User-facing buttons:

- Again
- Hard
- Good
- Easy

Future schedulers:

- apc-sm2-v1
- apc-fsrs-compatible-v1

## Server storage policy

For private study content:

- no server deck/card persistence
- no server Anki content persistence
- no server media persistence
- no server progress persistence by default

The APC server can still handle account, auth, billing/credits, public/shared features, and AI job routing.

## Future Google Drive sync

Google Drive sync should mirror the local library documents and media to the user's Drive appDataFolder only after the local data model is proven.

Google sync remains opt-in and is not enabled in this stage.

## Contract files

This stage adds:

- docs/design/buddies-local-library-schema-v1.json
- docs/design/anki-compatible-shadow-library-contract-v1.json

## Formatting note

This doc intentionally avoids nested Markdown code fences so PPB paste blocks are not broken.
