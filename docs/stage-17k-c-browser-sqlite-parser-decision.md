# Stage 17K-C — Browser SQLite Parser Decision

Date: 2026-06-28

## Summary

Stage 17K-C records the browser SQLite parser decision for APC Anki deck extraction.

Decision: use a locally vendored, pinned sql.js asset set for the first browser-local Anki metadata extraction proof.

## Why sql.js first

The immediate APC use case is:

1. User explicitly selects collection.anki2 or collection.anki21 in the browser.
2. Browser reads the selected file into memory.
3. SQLite parser imports the selected file as an in-memory database.
4. APC runs read-only metadata queries.
5. APC displays decks, note types, fields, templates, cards, and notes.
6. APC does not upload, persist, or write the Anki file.

sql.js fits this first proof because it is a browser-oriented SQLite implementation that can import an existing SQLite file as a typed array and query it entirely in the browser.

## Why not official SQLite WASM first

The official SQLite WASM project is a strong long-term option, especially if APC later needs more advanced browser SQLite behavior or durable browser-side SQLite storage.

For the first Anki extraction proof, it is broader than needed. The first proof only needs temporary in-memory read-only inspection of a user-selected file.

## Production dependency rule

Do not use a CDN dependency for production.

The future implementation should vendor pinned assets into the repo, likely under:

- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/

Expected asset types:

- sql-wasm.js
- sql-wasm.wasm
- license file
- checksum file
- source/version note

## Required checks before vendoring

Before adding sql.js assets, verify:

- exact package/version
- license compatibility
- SHA-256 of downloaded artifacts
- local static serving path
- browser load path
- no CDN reference
- no network fetch except same-origin static WASM load
- no upload of selected Anki files
- no Anki write behavior

## Browser extraction target

The browser proof should reproduce the Stage 17K-B-R3 local Python summary:

- Anki Deck1: 2 cards, 2 notes
- Anki Deck2: 1 card, 1 note
- Basic: 3 notes
- Fields: Front, Back
- Template: Card 1
- Source schema: decks, notetypes, fields, templates
- Safety: browser-local, no upload, no write

## Query model

The browser extractor should prefer the newer table-based Anki schema:

- decks.name for deck names
- notetypes.name for note type names
- fields.name for field names
- templates.name for card template names

It should keep fallback support for older col.decks and col.models metadata.

## Future flow

Stage 17K-D should be a dependency-vendor/checksum step only.

Stage 17K-E should add browser-local SQLite metadata extraction to the existing Profile Anki file picker.

Stage 17K-F should add a Study source picker:

- Study with Anki
- Study with My Decks

## Safety boundaries

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, CDN dependency, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included in this decision checkpoint.
