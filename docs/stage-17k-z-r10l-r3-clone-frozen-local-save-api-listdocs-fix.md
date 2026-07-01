# Stage 17K-Z-R10L-R3 — Clone Frozen Local Save API listDocs Fix

R10L-R3 fixes the namespace listing problem discovered during manual browser testing.

## Diagnostic finding

The live `APC_LOCAL_SAVE` object is frozen and sealed:

- `Object.isFrozen(APC_LOCAL_SAVE) === true`
- `Object.isExtensible(APC_LOCAL_SAVE) === false`

That explains why R10L/R10L-R2 could not attach a marker or replace `listDocs` in place.

## Change

R10L-R3 replaces `window.APC_LOCAL_SAVE` with a cloned frozen API object:

- all existing methods and properties are preserved
- `listDocs` is replaced with namespace-aware behavior
- `listDocs({ namespace: "study" })` falls back to `exportAll()`
- key-prefixed docs like `study/decks/v1` are returned

## Live deploy

Only VM200 frontend static files were deployed:

- `index.html`
- `privatepages/local-save-store.js`

No backend deploy occurred.

## No server persistence

This does not reintroduce private Study server persistence.

Study private data authority remains browser-local.
