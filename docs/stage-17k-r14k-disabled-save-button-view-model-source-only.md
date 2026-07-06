# Stage 17K-R14K — Disabled Save Button View Model Source-Only

## Status

Source-only helper.

No deploy.
No live UI change.
No script load.
No button.
No click handler.
No executor call.
No file write.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-view-model.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_VIEW_MODEL_R14K_SOURCE_ONLY

## Purpose

Defines the future disabled "Save current backup" button view model before adding any UI.

It uses the existing save action controller state to describe whether a later stage may show a disabled save action.

## Always disabled in R14K

R14K always returns:

- sourceOnly true
- deployed false
- uiLoaded false
- domElementCreated false
- buttonElementCreated false
- buttonVisibleNow false
- buttonDisabledNow true
- actionBoundToUi false
- clickHandlerAdded false
- clickHandlerCallsWriteExecutor false
- writeExecutorCalled false
- canWriteNow false
- writesEnabledNow false
- currentFileSaveEnabledNow false
- sameFileWriteEnabledNow false
- requiresLaterDeployStage true

## Future wording

Proposed future disabled label:

- Save current backup

Proposed helper text:

- Preview only.
- No file is saved, replaced, merged, restored, or overwritten.
- No Save button is rendered in R14K.
- No click handler is attached in R14K.
- A later explicit stage is required before any current-file save UI can exist.

## Safety

Source-only and not loaded by index.html.

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
No current-file save in live UI.
No same-file write path in live UI.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
No backup panel source change.
No mount source change.
