# stage-17k-r16cd-match-profile-backup-folder-card-style-source-only

## Result

Restyles the Profile local backup folder panel to visually match the existing Profile cards, including the Local Settings and Anki boxes.

## Scope

Source-only. No deploy, no SSH, no sudo, no backend upload, no Google Drive sync, and no Anki mutation.

## User-facing behavior

The Profile page keeps one local backup folder card for:

- Pick Backup Folder
- Scan folder
- Save current backup
- Download snapshot
- Preview backup file

The older Complete Backup diagnostics, Google Drive sync panel, and Local profile status card remain removed.

## Safety

Presentation-only CSS update. Backup read/write behavior is unchanged.
