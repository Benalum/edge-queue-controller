# stage-17k-r16ce-profile-backup-folder-card-style-guard-source-only

Source-only Profile UI cleanup after R16CD.

## Purpose

R16CB restored the correct Local backup folder workflow, but the browser view could still look plain if the stylesheet did not apply or was cached. R16CE adds a card-style guard that injects the same Profile-card styling at runtime and also rewrites the standalone CSS file.

## User-facing intent

The Profile page should show these clean boxes:

- Choose companion
- Local backup folder
- Anki

The Local backup folder panel should visually match the other Profile cards instead of appearing as plain text and unstyled browser buttons.

## Safety

- Source-only.
- No deploy.
- No SSH.
- No sudo.
- No backend upload.
- No Google Drive sync.
- No Anki write.
- No backup file write during this stage.

## Files changed

- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-panel.css`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backup-folder-card-style-guard.js`
- smoke/evidence/docs
