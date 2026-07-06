# Stage 17K-R14M — Record Disabled Save Button View Model Asset Not Loaded Proof

## Status

Browser proof passed.

## Baseline

R14L deployed the disabled "Save current backup" button view model as a direct static asset only.

R14L did not load the asset from `index.html`, did not reference it from the Profile mount or panel, did not render a button, and did not bind any click handler.

## Browser proof result

Console proof printed:

- PASS_R14L_DISABLED_SAVE_BUTTON_VIEW_MODEL_ASSET_NOT_LOADED_NO_UI_NO_WRITE

## Expected signed-out noise

A 401 network line from `/api/me` appeared while signed out and is expected.

## Asset availability proof

Browser proof verified:

- assetStatus 200
- assetHasMarker true
- assetHasViewModelFunction true
- assetHasStatusTextFunction true
- assetHasDisabledFlags true
- assetHasForbiddenWriteCode false

The deployed asset marker was:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY

## Not loaded proof

Browser proof verified:

- viewModelLoadedByScript false
- viewModelWindowPresent false

This confirms the disabled save button view model asset exists by direct URL, but is not loaded into the live Profile page.

## No live reference proof

Browser proof verified:

- mountStatus 200
- panelStatus 200
- mountReferencesViewModel false
- panelReferencesViewModel false

This confirms Profile mount and Profile panel do not reference:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL
- createDisabledSaveButtonViewModel

## Existing Profile status proof

Browser proof verified:

- hasVisibleStatusPreview true
- statusStillNoWrite true

The existing visible status preview still confirms:

- Can write now: false
- Writes enabled now: false
- Executor called: false

## No unsafe button proof

Browser proof verified:

- hasUnsafeButton false

Visible local backup buttons remained limited to:

- Choose local backup folder
- Download snapshot
- Preview backup file
- Open current backup file

No local-backup Save / Save current / Save backup / Apply / Restore / Merge / Overwrite button was added.

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
