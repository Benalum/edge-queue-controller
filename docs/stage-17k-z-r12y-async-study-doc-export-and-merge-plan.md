# Stage 17K-Z-R12Y — Async Study Doc Export and Merge Plan

## Status

Narrow VM200 static deploy plus merge-backup design checkpoint.

## Live fix

V2 backup download now awaits browser-local Study docs before creating the downloaded JSON file.

This is intended to fix the R12W/R12X issue where backupDocs listed Study docs but docs only contained media docs.

Required Study docs:

- study/cards/v1
- study/decks/v1
- study/progress/v1
- study/sessions/v1
- study/store-state/v1

Media docs:

- study/media/v1
- study/media-blobs/v1
- study/card-media-refs/v1
- study/media-manifest/v1
- study/anki-media/v1
- study/anki-imports/v1

## Backup file strategy

Timestamped JSON downloads should remain manual snapshots only.

They are useful for:

- saving a copy before risky changes
- moving data between browsers
- debugging backup schema

They should not be the only long-term backup model because repeated downloads create too many files.

## Backup set strategy

The planned long-term model is a backup set, not endless snapshot files.

A user-selected folder should contain stable paths like:

- buddies-who-study/manifest.json
- buddies-who-study/current.json
- buddies-who-study/study/cards.json
- buddies-who-study/study/decks.json
- buddies-who-study/study/progress.json
- buddies-who-study/study/sessions.json
- buddies-who-study/media/manifest.json
- buddies-who-study/media/blobs/

Each save can update or merge these files instead of creating a new timestamped JSON file.

## Merge rules

Planned merge rules:

- Decks merge by id and newer updatedAt wins.
- Cards merge by id and newer updatedAt wins.
- Sessions merge by id and duplicates are skipped.
- Progress is recomputed from cards and sessions where possible.
- Media deduplicates by SHA-256.
- Anki imports are immutable records by import id or source hash.
- Conflicts should be recorded instead of silently overwritten.

## Browser limitation

A normal browser download cannot safely overwrite an existing downloaded file.

Stable backup-set updates require the user to choose a folder with browser file-system access, or to select an existing backup file for preview/merge.

## Safety

No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.

## Deploy files

- index.html
- privatepages/profile-local-backups-panel.js
- privatepages/profile-local-backups-mount.js

## Next recommended stage

R12Z should add a source-only backup-set merge planner.

The planner should accept current local docs and an incoming backup payload, then produce a preview-only merge plan with no writes.
