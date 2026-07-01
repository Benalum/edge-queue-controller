# Stage 17K-Z-R12R — Disabled Local Media Vault Helper

## Status

Source-only helper checkpoint.

No frontend deploy.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study doc write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No UI mount.

## Added source

Added:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-media-vault.js

This file is not loaded by index.html yet.

## Purpose

Add a disabled browser-local media vault helper for future native card image support, Anki media support, backup export, restore import, and Companion current-card media display.

## Current behavior

The helper can:

- validate image-like file metadata
- classify media kind by MIME type
- create safe filenames
- build stable media IDs
- normalize media records
- normalize card media references
- create empty media vault state
- add media records to a manifest without persistence
- add card media references without persistence

The helper does not:

- mount UI
- modify existing cards
- persist media blobs
- write local storage
- write IndexedDB
- upload media
- fetch remote URLs
- parse Anki files
- parse APKG files
- call Companion
- deploy live

## Persistence state

Persistence is intentionally disabled in R12R.

These functions reject by design:

- storeMediaBlob
- loadMediaBlob
- deleteMediaBlob

## Privacy contract

This stage preserves:

- serverUpload false
- ankiSourceMutation false
- sourceMutation false
- localOnly true

## Next recommended stage

R12S should extend the local backup builder to include empty media docs and the schema/vault manifests, still without writing media blobs.
