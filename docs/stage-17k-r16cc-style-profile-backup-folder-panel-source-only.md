# stage-17k-r16cc-style-profile-backup-folder-panel-source-only

## Result

Adds styling for the single Profile local backup folder panel restored in R16CB.

## Scope

Source-only. No deploy, no SSH, no sudo, no backend upload, no Google Drive sync, and no Anki mutation.

## User-facing intent

Profile keeps one clean backup folder workflow:

- Pick Backup Folder
- Scan folder
- Save current backup
- Download snapshot
- Preview backup file

The older Complete Backup diagnostics, Google Drive sync panel, and Local profile status card remain removed from Profile.

## Files

- frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.css
- frontend/wrapper-ui/apc-wrapper-local/index.html

## Safety

The CSS patch changes presentation only. It does not alter backup write logic, restore logic, Anki policy, or server behavior.
