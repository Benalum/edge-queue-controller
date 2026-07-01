# Stage 17K-Z-R10L-R2 — Strong Local Save listDocs Namespace Patch

This stage strengthens the R10L namespace fix.

## Why R2 was needed

R10L source/static deploy succeeded, but live browser testing still showed:

- `APC_LOCAL_SAVE.listDocs({ namespace: "study" })` returned `0`
- `APC_LOCAL_SAVE.exportAll()` previously confirmed the expected `study/...` docs exist

## Change

R10L-R2 patches:

- the current `window.APC_LOCAL_SAVE` object
- any future reassignment of `window.APC_LOCAL_SAVE`

The patched `listDocs({ namespace })` falls back to `exportAll()` when the original namespace filter returns no matches.

It recognizes key-prefixed docs like:

- `study/cards/v1`
- `study/decks/v1`
- `study/progress/v1`
- `study/sessions/v1`
- `study/store-state/v1`

## Live deploy

Only VM200 frontend static files were deployed:

- `index.html`
- `privatepages/local-save-store.js`

No backend deploy occurred.

## No server persistence

This does not reintroduce private Study server persistence.

Study private data authority remains browser-local.
