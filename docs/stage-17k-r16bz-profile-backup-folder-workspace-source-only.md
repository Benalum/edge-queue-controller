# stage-17k-r16bz-profile-backup-folder-workspace-source-only

Source-only stage. No deploy, no SSH, no sudo, and no live site change.

## Purpose

Add a Profile **Backup folder workspace** so users can choose a local backup folder instead of manually managing one-off JSON files.

## Behavior

- Adds **Pick backup folder** when the browser supports writable directory access.
- Adds **Scan picked folder**.
- Adds **Save current to folder**.
- Looks for \.
- On save:
  - reads the existing current backup if present,
  - merges current browser-local data into it,
  - writes \ as a last-good copy when replacing an existing current file,
  - writes \,
  - writes a timestamped snapshot.
- Adds **Inspect folder read-only** fallback for browsers that can select folders but cannot write to them.
- Keeps **Download current backup** fallback.

## Safety

- Local folder only.
- No server upload.
- No Google Drive sync activation.
- No restore/merge into browser data.
- No Anki source writes.
