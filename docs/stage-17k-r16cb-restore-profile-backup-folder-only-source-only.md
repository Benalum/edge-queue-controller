# stage-17k-r16cb-restore-profile-backup-folder-only-source-only

Restores only the Profile local backup folder workflow that the user wanted to keep.

## Keeps visible in Profile

- Choose companion
- Companion preset and custom companion media
- Local backup folder panel
- Anki read-only picker

## Still removed from Profile

- Complete local backup diagnostics panel
- Old Buddies Who Study local backups diagnostics stack
- Google Drive sync
- Local profile/account status card

## Backup folder behavior

The new visible panel is named Local backup folder. It lets a user pick a folder, scans for buddies-who-study-current.json, and saves current browser-local data back into that folder. On save it writes buddies-who-study-current.json, buddies-who-study-current.previous.json when an older current file exists, and a timestamped snapshot JSON.

Chrome and Edge can use writable folder access. Firefox keeps the download/preview fallback because writable folder access is not supported there.

## Safety

No backend upload, no Google Drive sync, no server DB write, no restore/merge into browser data, and no Anki file writes. Anki remains read-only as a source; Buddies progress/media are saved only to Buddies Who Study local backup files.
