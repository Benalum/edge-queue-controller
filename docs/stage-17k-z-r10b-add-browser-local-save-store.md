# Stage 17K-Z-R10B — Browser Local Save Store

This stage adds the browser-local storage foundation for Buddies Who Study.

## Goal

Personal study/profile/deck/card data should be local-first in the user's browser. Later, the same document structure can sync to the user's Google Drive appDataFolder.

## Added module

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/local-save-store.js`

Loaded before study/profile/companion feature modules from:

- `frontend/wrapper-ui/apc-wrapper-local/index.html`

## Runtime API

The module exposes:

- `window.APC_LOCAL_SAVE`
- `window.APC_LOCAL_SAVE_POLICY`

Primary APIs:

- `getDoc(key)`
- `setDoc(key, value)`
- `patchDoc(key, patch)`
- `deleteDoc(key)`
- `listDocs(prefix)`
- `appendEvent(eventType, payload)`
- `listEvents(options)`
- `recordCardReview(review)`
- `putMedia(blobOrArrayBuffer, metadata)`
- `getMediaBlob(sha256)`
- `listMedia()`
- `exportAll()`
- `importDocs(payload)`
- `estimateStorage()`
- `requestPersistentStorage()`

## IndexedDB database

Database:

- `buddies_who_study_local_v1`

Object stores:

- `docs`
- `events`
- `media`

## Smart storage model

### Documents

Canonical JSON documents are stored by stable keys:

- `profile/preferences/v1`
- `study/decks/v1`
- `study/sessions/v1`
- `study/progress/v1`
- `companion/preferences/v1`
- `companion/local-memory/v1`
- `sync/manifest/v1`

### Progress

Progress is stored as compact events plus rollups. This avoids saving full card/deck payloads repeatedly.

Example rollups:

- `progress/cards/<cardId>/v1`
- `progress/decks/<deckId>/v1`
- `progress/daily/<YYYY-MM-DD>/v1`

### Media

Card images and other media are stored separately by SHA-256 hash. Cards should reference media by hash rather than embedding image bytes repeatedly.

This mirrors the useful idea behind Anki-style media management: keep card data and media files separate and avoid duplicate copies.

## Server storage policy

The module declares:

- `serverPersistenceAllowed: false`
- `deckCardServerUploadAllowed: false`
- `studyProgressServerUploadAllowed: false`
- `ankiContentServerUploadAllowed: false`

R10B does not wire existing feature modules yet. Follow-up stages should migrate features onto `window.APC_LOCAL_SAVE` and remove or disable any server persistence for private decks/cards/progress.

## Google Drive

No Google OAuth or Drive API work is performed in this stage. Google sync should later mirror these same local documents to appDataFolder.
