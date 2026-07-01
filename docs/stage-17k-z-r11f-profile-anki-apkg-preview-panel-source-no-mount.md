# Stage 17K-Z-R11F — Profile Anki APKG Preview Panel Source, No Mount

## Status

Source-only implementation checkpoint.

No deploy.
No UI activation.
No index.html script mount.
No profile.html script mount.
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

Add the source for a Profile Anki APKG preview panel without mounting it.

This panel source is the user-facing layer that can later let a user choose an APKG file from the Profile tab and preview it locally.

## Added source

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-anki-preview-panel.js

## Exported API

The panel exposes:

- APC_PROFILE_ANKI_PREVIEW_PANEL.marker
- APC_PROFILE_ANKI_PREVIEW_PANEL.createPreviewModel
- APC_PROFILE_ANKI_PREVIEW_PANEL.renderPreviewHtml
- APC_PROFILE_ANKI_PREVIEW_PANEL.renderPanel

## Current behavior

The panel is not mounted.

It is not added to index.html.

It is not added to profile.html.

It is not deployed.

A test harness can load it directly and call createPreviewModel with a File-like APKG object.

## Safety boundary

The panel does not:

- fetch network resources
- call backend routes
- write APC_LOCAL_SAVE docs
- write localStorage
- open IndexedDB
- mutate original Anki files
- parse SQLite rows
- extract media files
- deploy live UI

## Preview result

The panel can render a local preview with:

- file name
- file size
- APKG container yes/no
- collection.anki2 present yes/no
- collection.anki21 present yes/no
- media manifest present yes/no
- numeric media entry count
- total ZIP entry count
- warnings
- entry summaries

## Recommended R11G

Add a source-only Profile mount plan or gated source mount for the preview panel.

Do not deploy until explicitly approved.
