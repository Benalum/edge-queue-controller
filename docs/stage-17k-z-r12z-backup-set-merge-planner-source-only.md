# Stage 17K-Z-R12Z — Backup-Set Merge Planner Source-Only

## Status

Source-only checkpoint.

This stage adds a merge planner for Buddies Who Study local backups.

It is not loaded by index.html and is not deployed.

## Why this exists

Timestamped JSON downloads are useful manual snapshots, but they should not be the long-term backup model because users can end up with too many files.

The long-term model should be a backup set in a user-selected folder where stable files are updated or merged.

Example future backup set:

- buddies-who-study/manifest.json
- buddies-who-study/current.json
- buddies-who-study/study/cards.json
- buddies-who-study/study/decks.json
- buddies-who-study/study/progress.json
- buddies-who-study/study/sessions.json
- buddies-who-study/media/manifest.json
- buddies-who-study/media/blobs/

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-merge-planner.js

Marker:

- APC_LOCAL_BACKUP_MERGE_PLANNER_R12Z_SOURCE_ONLY

## Merge planner behavior

The planner compares current local docs with an incoming backup payload.

It produces a preview-only plan with:

- deck adds, updates, skips, conflicts
- card adds, updates, skips, conflicts
- session adds, updates, skips, conflicts
- media adds, updates, skips, conflicts
- card-media-ref adds, updates, skips, conflicts
- Anki import adds, updates, skips, conflicts
- doc presence summary
- warnings for missing docs
- errors for invalid backup kind

## Merge rules encoded

- Decks merge by id.
- Cards merge by id.
- Sessions merge by id.
- Media deduplicates by id, mediaId, sha256, hash, or filename fallback.
- Anki imports merge by id, importId, source hash, or fallback.
- Newer updatedAt wins when timestamps differ.
- Same timestamp with different content becomes a conflict.
- Progress is not directly merged. It should be recomputed before any future write.
- Store state is not directly merged. Canonical state should be separated from transient cache fields before any future write.

## Safety

The planner is preview-only:

- canWrite false
- writesEnabled false
- writeMode preview-only
- requiresExplicitConfirmation true
- overwriteExistingLocalData false

No backend deploy.
No frontend deploy.
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

## Next recommended stage

R13A should wire this planner into the Profile preview path as another preview-only view:

- select backup file
- show restore preview
- show merge preview
- still no apply or restore button
