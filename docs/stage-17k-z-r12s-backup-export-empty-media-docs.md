# Stage 17K-Z-R12S — Backup Export Empty Media Docs

## Status

Source-only adapter checkpoint.

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
No index.html loader change.

## Added source

Added:

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-media-export.js

This file is not loaded by index.html yet.

## Purpose

Prepare local backups to include empty media documents before real media writes exist.

This keeps backup and restore schema stable before adding image attachment UI, Anki media parsing, or Companion media rendering.

## Empty media docs added by adapter

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

## Current behavior

The adapter can:

- create an empty media-aware backup payload
- augment an existing backup payload with empty media docs
- validate that media docs exist
- preserve privacy flags
- report whether the disabled media vault is enabled

The adapter does not:

- write browser storage
- write IndexedDB
- read media files
- persist media blobs
- modify existing cards
- parse Anki
- parse APKG
- mount UI
- deploy live

## Privacy contract

The adapter preserves:

- serverUpload false
- ankiSourceMutation false
- sourceMutation false
- localOnly true
- originalAnkiBytesIncluded false by default

## Next recommended stage

R12T should add a backup restore preview helper that can read a selected backup file, validate the envelope and media docs, and show a summary with no writes.
