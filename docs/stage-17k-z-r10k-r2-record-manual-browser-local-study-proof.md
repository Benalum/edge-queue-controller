# Stage 17K-Z-R10K-R2 — Manual Browser Local Study Proof

This checkpoint records the signed-in browser manual smoke proof for the local-only Study cutover.

## Browser result

The user manually tested the live site after R10J-R3.

Actions performed:

- signed in
- opened Study
- created a new deck
- created a new card
- refreshed the page
- confirmed the deck and card stayed visible

## Post-refresh report

The browser report showed:

- `studyStoreAvailable: true`
- `studyStoreMode: "browser-local-only"`
- `localSaveAvailable: true`
- `deckCount: 2`
- `cardCount: 2`
- `pass: true`

## Forced IndexedDB mirror report

After calling `flushLocalSaveMirror()`, the browser report showed:

- `studyStoreMode: "browser-local-only"`
- `deckCount: 2`
- `cardCount: 2`
- `docsByNamespaceCount: 0`
- `exportStudyDocCount: 5`
- `pass: true`

IndexedDB/APC_LOCAL_SAVE export contained these expected study document keys:

- `study/cards/v1`
- `study/decks/v1`
- `study/progress/v1`
- `study/sessions/v1`
- `study/store-state/v1`

## Interpretation

This is a passing manual browser proof.

`docsByNamespaceCount=0` is not treated as failure because `exportAll()` confirmed the expected study documents by key. The namespace filter behavior can be improved later, but the durable local save content exists.

## Policy proof

Private Study is now browser-local:

- frontend Study works after refresh
- backend private study persistence routes were removed live
- removed private study endpoints returned 404 during R10J-R3
- static Study code has zero `/api/study` persistence references
- IndexedDB/APC_LOCAL_SAVE contains the expected Study docs

## Follow-up candidate

A later cleanup stage can improve `APC_LOCAL_SAVE.listDocs({ namespace: "study" })` so namespace filtering returns the same study docs that `exportAll()` already exposes by key.
