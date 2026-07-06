# Stage 17K-R14Z-R2 — Visible Disabled Save Button Mount Plan Source-Only

## Status

Recovered and completed after the first R14Z attempt refused due a dirty working tree with partial untracked R14Z files.

The partial R14Z paths were audited, then only those exact partial paths were removed and rebuilt as R14Z-R2.

## New file

- frontend/wrapper-ui/apc-wrapper-local/privatepages/local-backup-current-file-disabled-save-button-mount-plan.js

Marker:

- APC_LOCAL_BACKUP_CURRENT_FILE_DISABLED_SAVE_BUTTON_MOUNT_PLAN_R14Z_R2_SOURCE_ONLY

## Purpose

Defines a safe source-only plan for a future visible disabled "Save current backup" button.

This helper does not mount anything. It only describes where a future disabled button would go and confirms all write-related flags remain false.

## Planned future placement

- Target section: Current backup save plan
- Target placement: after-current-backup-save-action-status-preview
- Future button text: Save current backup
- Future button disabled: true

## Always disabled

The plan always returns:

- sourceOnly true
- deployed false
- uiLoaded false
- mountPlanOnly true
- domElementCreated false
- elementInserted false
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
- requiresLaterUiMountStage true
- requiresLaterBrowserProof true

## Safety

Source-only and not loaded by index.html.

No deploy.
No live UI change.
No script load.
No Profile mount change.
No panel change.
No DOM creation.
No button insertion.
No click handler.
No executor call.
No file write.
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
