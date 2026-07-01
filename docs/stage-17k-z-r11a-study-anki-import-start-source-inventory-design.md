# Stage 17K-Z-R11A — Study/Anki Import Start Source Inventory and Design

## Status

Source-only design and inventory stage.

No deploy.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.

## Current checkpoint

Stage 17K-Z-R10N completed the browser-local Study persistence checkpoint.

Important current state:

- Study private user data authority is browser-local.
- Private Study server persistence routes were removed live.
- APC_LOCAL_SAVE.listDocs with namespace study must return only Study docs.
- Anki decks/cards and private Study data must stay browser-local.
- Original Anki files must not be mutated.

## R11A goal

Design the first browser-local Anki-compatible import/read path.

The goal is not full Anki replacement yet. The goal is a safe local import foundation that can read apkg content in the browser, copy supported data into Buddies local docs, and preserve original Anki identity metadata for future round-trip/export planning.

## MVP boundary

The first MVP path should:

1. Use browser File API.
2. Accept apkg or a tiny local fixture first.
3. Parse package metadata locally.
4. Extract package-level identity and collection metadata.
5. Copy/import supported notes/cards/media metadata into Buddies local docs.
6. Never mutate the original apkg, collection.anki2, or media files.
7. Never upload private Anki content to CT203 or any server route.

## Non-goals

- No server storage of Anki decks, cards, notes, media, progress, or private Study state.
- No backend Study persistence route reintroduction.
- No Google Drive sync.
- No Anki source file mutation.
- No full scheduler implementation in this stage.
- No libanki-backed server workflow in this stage.
- No automatic export back into a user's original Anki file.

## Existing local docs to preserve

The current Study local namespace remains:

- study/decks/v1
- study/cards/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

R11A adds design-only target docs for imported Anki-compatible content.

## Proposed new local docs

### study/import-sources/v1

Tracks user-selected local sources without storing absolute private filesystem paths unless the browser provides only safe display names.

Suggested shape:

    {
      "sources": [
        {
          "id": "src_local_...",
          "kind": "anki-apkg",
          "displayName": "biology.apkg",
          "sizeBytes": 123456,
          "lastModified": 1780000000000,
          "createdAt": "2026-07-01T00:00:00.000Z",
          "contentSha256": "optional-browser-computed-hash",
          "status": "imported"
        }
      ]
    }

### study/anki-packages/v1

Tracks package import metadata.

    {
      "packages": [
        {
          "id": "anki_pkg_...",
          "sourceId": "src_local_...",
          "originalFilename": "biology.apkg",
          "collectionSchema": "anki2",
          "collectionModified": 1780000000,
          "deckCount": 2,
          "noteCount": 100,
          "cardCount": 150,
          "mediaCount": 20,
          "importedAt": "2026-07-01T00:00:00.000Z"
        }
      ]
    }

### study/anki-notes/v1

Preserves Anki note identity and fields.

    {
      "notes": [
        {
          "id": "anki_note_...",
          "packageId": "anki_pkg_...",
          "ankiNoteId": 123,
          "guid": "original-note-guid",
          "modelId": 456,
          "noteTypeName": "Basic",
          "fields": ["Front", "Back"],
          "tags": ["chapter1"],
          "sortField": "Front",
          "contentSha256": "..."
        }
      ]
    }

### study/anki-cards/v1

Preserves card identity, deck mapping, ordinal, and template relationship.

    {
      "cards": [
        {
          "id": "anki_card_...",
          "packageId": "anki_pkg_...",
          "noteLocalId": "anki_note_...",
          "ankiCardId": 789,
          "ankiNoteId": 123,
          "deckId": 111,
          "deckPath": "Biology::Chapter 1",
          "ordinal": 0,
          "templateName": "Card 1",
          "queue": 0,
          "due": 0
        }
      ]
    }

### study/anki-media/v1

Preserves media mapping and hashes without uploading files.

    {
      "media": [
        {
          "id": "anki_media_...",
          "packageId": "anki_pkg_...",
          "originalFilename": "image001.png",
          "packageMediaKey": "0",
          "mimeType": "image/png",
          "sizeBytes": 12345,
          "contentSha256": "..."
        }
      ]
    }

### study/import-runs/v1

Records import attempt results.

    {
      "runs": [
        {
          "id": "import_run_...",
          "sourceId": "src_local_...",
          "packageId": "anki_pkg_...",
          "startedAt": "2026-07-01T00:00:00.000Z",
          "finishedAt": "2026-07-01T00:00:01.000Z",
          "status": "completed",
          "warnings": [],
          "errors": [],
          "counts": {
            "decks": 2,
            "notes": 100,
            "cards": 150,
            "media": 20
          }
        }
      ]
    }

## Identity preservation requirements

The importer must preserve:

- note GUID
- original note id when available
- original card id when available
- card ordinal
- deck id
- deck path
- note type/model id
- note type/model name
- template name
- original media filename
- package media key
- content hashes

## Import behavior

The import operation copies supported content into Buddies local docs.

It does not edit or write back to:

- the selected apkg
- collection.anki2
- original media files
- the user's Anki profile
- any server

## Source inventory targets

Primary frontend files:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-store.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-save-store.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/study.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js
- frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js

Existing browser SQLite assets:

- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/sql-wasm.js
- frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs/sql-wasm.wasm

## Recommended R11B after this stage

Implement a disabled/browser-local import module skeleton with no UI activation:

- privatepages/anki-import-local.js
- safe exported helpers only
- no network calls
- no backend routes
- fixture-based smoke only
- parse only minimal package structure first
