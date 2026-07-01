# Stage 17K-Z-R10N — R10M Browser Proof, Source Refresh, and Study/Anki Handoff

This checkpoint records the final browser proof after R10M and prepares the source refresh handoff for the next Study/Anki import chat.

## R10M browser proof

After hard refresh on the live Study page, the browser check showed:

- `patchMarkerR10M: true`
- `deckCount: 2`
- `cardCount: 2`
- `docsByNamespaceCount: 5`
- `expectedKeysPresent: 5`
- `hasSyncManifest: false`
- `pass: true`

## Exact docs returned by listDocs

`APC_LOCAL_SAVE.listDocs({ namespace: "study" })` returned exactly:

- `study/cards/v1`
- `study/decks/v1`
- `study/progress/v1`
- `study/sessions/v1`
- `study/store-state/v1`

It no longer returned:

- `sync/manifest/v1`

## Current Study local-only status

Study now has the intended browser-local-only private data posture:

- decks/cards persist after refresh
- `study-store.js` has zero private `/api/study` persistence references
- `APC_LOCAL_SAVE` is live
- `APC_LOCAL_SAVE.listDocs({ namespace: "study" })` returns the expected Study docs
- removed private study backend persistence endpoints return 404 live
- no wrapper guard or 403/410 bandage was used

## Next chat direction

Next work should focus on Study/Anki import, beginning with a local Anki-compatible import path:

1. Browser-local file picker for `.apkg`, `.anki2`, or exported Anki-like test fixtures.
2. Read-only parsing/import into Buddies local IndexedDB/APC_LOCAL_SAVE.
3. Preserve Anki identities:
   - note GUID
   - card ordinal
   - deck path
   - note type
   - template name
   - original media filename
   - content hashes
4. Keep original Anki files unchanged.
5. Keep Anki-derived user content browser-local only.
6. Add UI mode choice:
   - Study Anki Read-Only
   - Import to Buddies Library
   - Compare/Re-import
   - Export later

## Non-goals for next chat

Do not add server-side private deck/card storage.

Do not mutate Anki source files.

Do not add Google Drive sync yet.

Do not reopen signup.
