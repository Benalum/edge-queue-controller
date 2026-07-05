# Stage 17K-R13Q-R7 — Fix Download Snapshot getPanelApi

## Status

Narrow VM200 static deploy.

## Why

Browser console proof showed Download snapshot did not create a file because the click handler threw:

- ReferenceError: getPanelApi is not defined

## Fix

Defines getPanelApi in profile-local-backups-mount.js so the existing R12Y download click handler can reach window.APC_PROFILE_LOCAL_BACKUPS_PANEL.

## Deployed files

- index.html
- privatepages/profile-local-backups-mount.js

## Safety

Browser download handler fix only.

No backend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No local Study restore write.
No same-file write path.
No privatepages.js change.
No Profile fragment change.
No Profile backup panel source change.
