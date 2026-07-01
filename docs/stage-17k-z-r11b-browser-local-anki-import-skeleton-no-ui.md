# Stage 17K-Z-R11B — Browser-Local Anki Import Skeleton, No UI

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
No real apkg parsing activation.

## Goal

Add the first disabled browser-local importer module for Anki-compatible package metadata.

This stage creates a planning/skeleton module only. It can validate a tiny Anki-like package summary fixture and produce an import plan shaped like the local Study docs proposed in R11A.

## Added source

- frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-import-local.js

The module exposes:

- APC_ANKI_IMPORT_LOCAL.marker
- APC_ANKI_IMPORT_LOCAL.docKeys
- APC_ANKI_IMPORT_LOCAL.supportedExtensions
- APC_ANKI_IMPORT_LOCAL.isSupportedFileName
- APC_ANKI_IMPORT_LOCAL.describeFileSource
- APC_ANKI_IMPORT_LOCAL.validatePackageSummary
- APC_ANKI_IMPORT_LOCAL.createImportPlan
- APC_ANKI_IMPORT_LOCAL.readApkgMetadataDisabled

## Local docs shaped by the plan

The disabled skeleton can create a planned docs object for:

- study/import-sources/v1
- study/anki-packages/v1
- study/anki-notes/v1
- study/anki-cards/v1
- study/anki-media/v1
- study/import-runs/v1

## Safety boundary

The module does not call network APIs.
The module does not call backend routes.
The module does not call APC_LOCAL_SAVE write helpers.
The module does not call IndexedDB directly.
The module does not mutate original Anki files.
The module does not activate UI.
The module does not parse real apkg files yet.

The returned import plan explicitly reports:

- writesOriginalAnki false
- writesServer false
- writesLocalDocs false

## Fixture smoke

The smoke fixture is:

- ops/smoke/fixtures/stage-17k-z-r11b-minimal-apkg-summary.json

It contains one deck, one note, one card, and one media record.

The smoke checks that identity fields survive planning:

- note GUID
- card ordinal
- deck path
- template name
- original media filename
- content hash

## Recommended R11C

Add an unmounted UI import panel draft that lets a test harness call the disabled importer with a synthetic File-like object. Keep it unmounted and do not add it to index.html until a separate deploy stage is approved.
