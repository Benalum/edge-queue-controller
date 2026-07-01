# Stage 17K-Z-R11E — Profile Anki APKG Preview Bridge, No UI

## Status

Source-only implementation checkpoint.

No deploy.
No UI activation.
No index.html script mount.
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

Add a small bridge helper for the existing Profile Anki source path.

R11C added APC_ANKI_IMPORT_LOCAL.inspectApkgFile.

R11E adds APC_PROFILE_ANKI_IMPORT_BRIDGE.createProfileAnkiPreview so a Profile-file chooser can later pass a browser File-like object into the local APKG inspector and receive a safe preview.

## Added source

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-import-bridge.js

## Exported API

The bridge exposes:

- APC_PROFILE_ANKI_IMPORT_BRIDGE.marker
- APC_PROFILE_ANKI_IMPORT_BRIDGE.createProfileAnkiPreview
- APC_PROFILE_ANKI_IMPORT_BRIDGE.buildPreviewFromInspection

## Preview fields

The preview returns:

- sourceSurface profile
- mode apkg-preview-only
- disabledPreviewOnly true
- writesOriginalAnki false
- writesServer false
- writesLocalDocs false
- file name
- file size
- APKG container yes/no
- collection.anki2 present yes/no
- collection.anki21 present yes/no
- media manifest present yes/no
- numeric media entry count
- warnings
- ZIP entry summaries

## Safety boundary

This helper does not:

- fetch network resources
- call backend routes
- call APC_LOCAL_SAVE writes
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite rows
- extract media files
- mount UI
- deploy anything

## Why this is the right next step

R11D showed the old Profile Anki work exists and should not be bypassed.

This bridge lets the Profile path reuse the new R11C APKG inspector instead of creating a competing Anki import flow.

## Recommended R11F

Inspect the live-loaded frontend script list and decide whether to add this bridge to the private Profile page in a later source-only UI stage.

R11F should still avoid deploy unless explicitly approved.
