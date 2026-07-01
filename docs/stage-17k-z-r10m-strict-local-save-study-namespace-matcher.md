# Stage 17K-Z-R10M — Strict Local Save Study Namespace Matcher

This stage tightens the R10L-R3 local-save namespace matcher.

## Problem

R10L-R3 successfully made `APC_LOCAL_SAVE.listDocs({ namespace: "study" })` return the expected Study docs, but it also returned:

- `sync/manifest/v1`

That happened because the broad matcher scanned nested manifest content.

## Change

R10M replaces the matcher with strict namespace behavior.

`listDocs({ namespace: "study" })` should now match only:

- primary doc keys equal to `study`
- primary doc keys beginning with `study/`
- primary doc keys beginning with `study:`
- explicit namespace/ns/scope fields equal to `study`

It no longer matches nested manifest values.

## Live deploy

Only VM200 frontend static files were deployed:

- `index.html`
- `privatepages/local-save-store.js`

No backend deploy occurred.

## No server persistence

This does not reintroduce private Study server persistence.

Study private data authority remains browser-local.
