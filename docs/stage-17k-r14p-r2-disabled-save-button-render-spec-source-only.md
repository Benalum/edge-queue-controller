# Stage 17K-R14P-R2 — Disabled Save Button Render Spec Source-Only

## Status

Source-only helper.

R14P-R1 timed out before writing any files. R14P-R2 is a shorter retry.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-render-spec.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_RENDER_SPEC_R14P_R2_SOURCE_ONLY

## Purpose

Defines a declarative future disabled "Save current backup" button render spec.

The helper does not create DOM, insert a button, attach a click handler, call the write executor, or write a file.

## Always disabled

The render spec always returns:

- sourceOnly true
- deployed false
- uiLoaded false
- renderSpecOnly true
- domElementCreated false
- elementInserted false
- buttonElementCreated false
- buttonVisibleNow false
- buttonDisabledNow true
- renderAllowedNow false
- actionBoundToUi false
- clickHandlerAdded false
- clickHandlerCallsWriteExecutor false
- writeExecutorCalled false
- canWriteNow false
- writesEnabledNow false
- currentFileSaveEnabledNow false
- sameFileWriteEnabledNow false
- requiresLaterDeployStage true
- requiresLaterUiMountStage true

## Safety

Source-only and not loaded by index.html.

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
No privatepages.js change.
No Profile fragment change.
No backup panel source change.
No mount source change.
