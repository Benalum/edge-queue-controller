# Stage 17K-R13V — Profile Save Writer Plan Preview, No Write

## Status

Narrow VM200 static deploy.

## Purpose

Shows the future current backup save writer plan inside the Profile local backups UI.

## User-facing behavior

Adds a preview-only section:

- Current backup save plan

The section displays the same plan proven in the R13T/R13U browser console proof.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js

## Not changed

- No Save button
- No Apply button
- No Restore button
- No Merge button
- No Overwrite button
- No current-file save
- No same-file write path
- No File System Access write stream

## Safety

The UI preview calls only the source-only save writer helper.

The helper still reports:

- canWrite false
- writesEnabled false
- sameFileWriteEnabled false
- currentFileWriteEnabled false
- previousFileWriteEnabled false

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
No current browser data mutation.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.
No backup panel source change.
