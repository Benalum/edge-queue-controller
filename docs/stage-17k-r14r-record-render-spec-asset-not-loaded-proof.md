# Stage 17K-R14R — Record Render Spec Asset Not Loaded Proof

## Status

Browser proof passed.

## Baseline

R14Q deployed the disabled "Save current backup" render spec as a direct static asset only.

The asset is available by direct URL, but it is not loaded by `index.html`, not present on `window`, and not referenced by Profile mount or Profile panel.

## Browser proof result

Console proof printed:

- PASS_R14Q_RENDER_SPEC_ASSET_NOT_LOADED_NO_UI_NO_BINDING

## Expected signed-out noise

A 401 network line from `/api/me` appeared while signed out and is expected.

## Render spec not-loaded proof

Browser proof verified:

- renderSpecLoadedByScript false
- renderSpecWindowPresent false

## View model still-loaded proof

Browser proof verified:

- viewModelLoadedByScript true
- viewModelWindowPresent true

## Asset availability proof

Browser proof verified:

- assetStatus 200
- assetHasMarker true
- assetHasRenderSpecFunction true
- assetHasRenderSpecTextFunction true
- assetHasDisabledFlags true
- assetHasForbiddenDomOrWriteCode false

The deployed render spec marker was:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY

## Static dependency proof

Browser proof verified:

- mountStatus 200
- panelStatus 200

## No binding proof

Browser proof verified:

- mountReferencesRenderSpec false
- panelReferencesRenderSpec false

This confirms Profile mount and Profile panel do not reference:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC
- createDisabledSaveButtonRenderSpec

## Existing no-write status proof

Browser proof verified:

- hasVisibleStatusPreview true
- statusStillNoWrite true

The existing visible status preview still confirmed:

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
