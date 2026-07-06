# Stage 17K-R14L — Deploy Disabled Save Button View Model Asset Not Loaded

## Status

Narrow VM200 static asset deploy.

## Deployed file

- privatepages/local-backup-current-file-disabled-save-button-view-model.js

## Not loaded

The asset is available by direct URL, but `index.html` does not load it.

Profile mount and Profile panel do not reference it.

## Purpose

Makes the R14K disabled "Save current backup" button view model available as a static asset for later proof.

## Safety

No source behavior change.
No index load.
No live UI change.
No button.
No click handler.
No executor call.
No file write.
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
