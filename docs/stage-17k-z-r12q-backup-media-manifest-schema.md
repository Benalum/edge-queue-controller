# Stage 17K-Z-R12Q — Backup and Media Manifest Schema

## Status

Source-only schema checkpoint.

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
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No UI mount.

## Added source

Added:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-schema.js

This file is not loaded by index.html yet.

## Purpose

Define the browser-local schema contract for future local backup, restore, media, Anki media, and Companion current-card media work.

## Schema coverage

The helper defines:

- backup kind
- backup schema version
- media schema version
- primary Study doc keys
- media doc keys
- privacy flags
- empty backup manifest builder
- empty media manifest builder
- empty card media reference builder
- media item normalization
- card media reference normalization
- backup envelope validation
- media manifest validation
- card media reference validation

## Local doc keys

Existing Study docs:

- study/cards/v1
- study/decks/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

Planned media docs:

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

## Privacy contract

Every schema path keeps these rules:

- serverUpload false
- ankiSourceMutation false
- sourceMutation false
- localOnly true
- originalAnkiBytesIncluded false by default

## Not implemented yet

This stage does not:

- write media
- read media files
- store media blobs
- parse Anki SQLite
- parse APKG media
- mount a UI
- deploy anything live
- change existing local backup behavior

## Next recommended stage

R12R should add a disabled browser-local media vault helper.

The media vault helper should remain unmounted and source-only, with image-only metadata helpers and no writes unless explicitly called.
