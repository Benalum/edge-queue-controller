# Stage 17K-R14F — Record Save Action Controller Asset-Not-Loaded Proof

## Status

Browser proof passed.

## Baseline

R14E deployed the R14D save action controller as a static asset only.

The controller asset exists on VM200, but is intentionally not loaded by Profile.

## Browser proof result

Console proof printed:

- PASS_R14E_SAVE_ACTION_CONTROLLER_ASSET_NOT_LOADED

## Expected signed-out noise

A 401 network line from `/api/me` appeared while signed out and is expected.

## Asset proof

Browser fetch verified:

- controllerAssetStatus 200
- controllerHasMarker true
- controllerHasStateFunction true
- controllerHasViewModelFunction true
- controllerHasNoWriteFlags true

The fetched asset contained:

- APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER_R14D_SOURCE_ONLY
- createSaveCurrentBackupActionState
- createDisabledActionViewModel
- executorCallAllowedNow: false
- writesEnabledNow: false
- canWriteNow: false

## Not-loaded proof

Browser page inspection verified:

- controllerLoadedByScript false
- controllerWindowPresent false

This means the save action controller was available as a static file but was not executed by the Profile page.

## Executor baseline proof

Browser page inspection verified:

- executorWindowPresent true

The already-loaded write executor remained present from R14B.

## Profile safety proof

Browser page inspection verified:

- savePlanPreviewStillVisible true
- hasUnsafeButton false

The visible buttons did not include a local-backup Save / Save current / Save backup / Apply / Restore / Merge / Overwrite action.

Existing visible local backup buttons remained:

- Choose local backup folder
- Download snapshot
- Preview backup file
- Open current backup file

## No controller binding proof

Browser proof fetched and inspected the live mount and panel assets.

Verified:

- mountStatus 200
- panelStatus 200
- mountReferencesController false
- panelReferencesController false

This confirms that neither Profile mount nor Profile panel calls or references:

- APC_LOCAL_BACKUP_CURRENT_FILE_SAVE_ACTION_CONTROLLER
- createSaveCurrentBackupActionState

## Safety

Docs/evidence only.

No source mutation.
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
No local Study restore write.
No current-file save in live UI.
No same-file write path in live UI.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
