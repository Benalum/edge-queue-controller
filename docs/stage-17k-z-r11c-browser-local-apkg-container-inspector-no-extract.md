# Stage 17K-Z-R11C — Browser-Local APKG Container Inspector, No Extract

## Status

Source-only implementation checkpoint.

No deploy.
No UI activation.
No backend route addition.
No server private Study persistence.
No DB write.
No signup change.
No Google Drive or OAuth work.
No email send.
No Anki source file mutation.
No local Study doc write.
No real SQLite collection parsing.
No media extraction.

## Goal

Extend the disabled R11B browser-local importer skeleton with a read-only APKG ZIP container inspector.

This stage proves the browser-local importer can inspect an APKG container enough to detect package entries:

- collection.anki2
- collection.anki21
- media
- numeric top-level media files

## Added API

The existing APC_ANKI_IMPORT_LOCAL object now also exposes:

- apkgInspectorMarker
- inspectZipContainer
- inspectApkgContainer
- inspectApkgFile

## Safety boundary

The inspector only reads a provided ArrayBuffer or browser File-like object.

It does not:

- fetch network resources
- call backend routes
- write APC_LOCAL_SAVE docs
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite
- extract media
- activate UI

## Acceptance proof

The smoke creates a tiny temporary APKG-like ZIP fixture with:

- collection.anki2
- media
- one numeric media entry

Then Node loads the browser module and verifies:

- the file is detected as a ZIP
- the file is detected as an APKG container
- collection.anki2 is present
- media is present
- numeric media entry is present
- writesOriginalAnki is false
- writesServer is false
- writesLocalDocs is false

## Recommended R11D

Add local extraction support for only the collection database entry and media JSON entry into memory. Keep it no-write and fixture-only. Do not parse SQLite rows yet.
