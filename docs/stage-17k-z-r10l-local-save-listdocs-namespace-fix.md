# Stage 17K-Z-R10L — Local Save listDocs Namespace Fix

This stage fixes the local-save namespace listing gap found during R10K manual browser smoke.

## Problem

R10K proved browser-local Study persistence worked:

- decks/cards survived refresh
- `APC_LOCAL_SAVE.exportAll()` showed expected study docs

But this call returned zero docs:

    APC_LOCAL_SAVE.listDocs({ namespace: "study" })

while `exportAll()` showed key-prefixed docs such as:

- `study/cards/v1`
- `study/decks/v1`
- `study/progress/v1`
- `study/sessions/v1`
- `study/store-state/v1`

## Change

`local-save-store.js` now hardens `listDocs({ namespace })` so namespace filtering also recognizes key-prefixed docs like `study/...`.

## Live deploy

Only VM200 frontend static files were deployed:

- `index.html`
- `privatepages/local-save-store.js`

No backend deploy occurred.

## No server persistence

This does not reintroduce private Study server persistence.

The Study private data authority remains browser-local.
