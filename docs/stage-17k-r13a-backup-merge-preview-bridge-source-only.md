# Stage 17K-R13A — Backup Merge Preview Bridge Source-Only

## Status

Source-only checkpoint.

No deploy.
No live UI change.

## New source file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-merge-preview-bridge.js

Marker:

- APC_PROFILE_LOCAL_BACKUPS_MERGE_PREVIEW_BRIDGE_R13A_SOURCE_ONLY

## Purpose

This bridge connects three source-only pieces:

- current local backup payload from the Profile local backups panel
- restore preview helper
- backup-set merge planner

It creates a Profile-level preview that says what would happen if an incoming backup were merged with the current browser-local Study data.

## Preview-only outputs

The bridge returns:

- restorePreview
- mergePlan
- combined warnings
- combined errors
- formatted text
- formatted HTML

## Safety

The bridge is preview-only:

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

R13B should deploy and wire this into the existing Preview backup file button.

R13B should still remain preview-only:

- load local-backup-merge-planner.js
- load profile-local-backups-merge-preview-bridge.js
- when a backup file is previewed, show restore preview and merge preview
- do not add an Apply, Merge, Restore, or Overwrite button
