# Stage 17K-R15B-R2 — Record Mount Plan Asset Not Loaded Proof

## Status

Browser proof passed.

## Recovery note

The first R15B attempt refused because unrelated untracked local files were present:

- import numpy as np.py
- numpy_env/

Those files were moved outside the repository into a Desktop quarantine folder before this docs-only proof record was created.

No APC source files were changed during quarantine.

## Baseline

R15A deployed the disabled "Save current backup" mount plan as a direct static asset only.

The asset is available by direct URL, but it is not loaded by `index.html`, not present on `window`, and not referenced by Profile mount or Profile panel.

## Browser proof result

Console proof printed:

- PASS_R15A_MOUNT_PLAN_ASSET_NOT_LOADED_NO_UI_NO_BINDING

## Expected signed-out noise

A 401 network line from `/api/me` appeared while signed out and is expected.

## Page proof

Browser proof was run on:

- https://buddieswhostudy.com/profile

Browser proof verified:

- profileButtonsPresent true

Visible local backup buttons were present:

- Choose local backup folder
- Download snapshot
- Preview backup file
- Open current backup file

## Mount plan not-loaded proof

Browser proof verified:

- mountPlanLoadedByScript false
- mountPlanWindowPresent false

## Prior safe layers still loaded

Browser proof verified:

- htmlRendererLoadedByScript true
- htmlRendererWindowPresent true
- renderSpecLoadedByScript true
- renderSpecWindowPresent true
- viewModelLoadedByScript true
- viewModelWindowPresent true
- controllerWindowPresent true
- executorWindowPresent true
- panelWindowPresent true

## Asset availability proof

Browser proof verified:

- assetStatus 200
- assetHasMarker true
- assetHasPlanFunction true
- assetHasPlanTextFunction true
- assetHasDisabledFlags true
- assetHasForbiddenDomOrWriteCode false

The deployed mount-plan marker was:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY

## Static dependency proof

Browser proof verified:

- mountStatus 200
- panelStatus 200

## No binding proof

Browser proof verified:

- mountReferencesMountPlan false
- panelReferencesMountPlan false

This confirms Profile mount and Profile panel do not reference:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN
- createVisibleDisabledSaveButtonMountPlan

## Existing no-write status proof

Browser proof verified:

- hasVisibleStatusPreview true
- statusStillNoWrite true

The visible status preview still confirmed:

- Can write now: false
- Writes enabled now: false
- Executor called: false

## No inserted button proof

Browser proof verified:

- insertedPreviewButtonPresent false
- mountedButtonPresent false

No element matching either selector was inserted into the DOM:

- data-apc-local-backup-disabled-save-button-html-preview-r14u="true"
- data-apc-local-backup-disabled-save-button-mounted-r14z-r2="true"

## No unsafe button proof

Browser proof verified:

- hasUnsafeButton false

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
