# Stage 17K-R14I-R2 — Visible Save Action Status Preview, No Button, No Write

## Status

Narrow VM200 static deploy.

## Recovery note

R14I-R1 failed before deploy during source verification because `git diff --check` reported a trailing blank line at EOF in `profile-local-backups-mount.js`.

R14I-R2 restored the partial local patch, saved the failed diff into evidence, and reapplied the preview with clean EOF handling.

## Purpose

Adds a visible Profile status preview for the current backup save action controller.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js

## Visible behavior

Adds a status-only section after the existing current backup save writer plan preview.

Selector:

- data-apc-local-backup-save-action-status-preview-r14i-r2="true"

Text selector:

- data-apc-local-backup-save-action-status-preview-text-r14i-r2="true"

## No button

No Save button.
No Apply button.
No Restore button.
No Merge button.
No Overwrite button.

## No write binding

The preview calls only:

- createSaveCurrentBackupActionState

The preview does not call:

- executeCurrentBackupWrite

The preview does not contain:

- createWritable
- .write
- .close
- showSaveFilePicker
- showDirectoryPicker

## Expected status values

The preview should show:

- Future eligible: true
- Future save button may be shown later: true
- Can write now: false
- Writes enabled now: false
- Executor call allowed now: false
- Executor called: false
- Legacy backend cache fields removed: 4
- After legacy backend cache fields: none

## Safety

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
