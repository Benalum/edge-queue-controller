# Stage 17K-R16G — Load Study Card Image Helper Contracts, No UI/Binding

## Status

Narrow VM200 static index deploy.

## Changed file

- frontend/wrapper-ui/apc-wrapper-local/index.html

## Loaded assets

- privatepages/study-card-images-local-only-contract.js
- privatepages/study-card-images-local-storage-adapter-contract.js
- privatepages/study-card-images-backup-manifest-contract.js
- privatepages/study-card-images-card-editor-ui-plan.js

## Purpose

Loads the source-only card image helper contracts so browser proof can verify their window exports and inert safety flags before any UI integration.

## Exact delta

Compared with the previous checkpoint:

- removed scripts: none
- added scripts: four study-card image helper scripts only

## No UI binding

R16G does not modify:

- study-store.js
- privatepages/pages/study.html
- profile-local-backups-mount.js
- profile-local-backups-panel.js
- privatepages.js
- privatepages/pages/profile.html

## Safety

No card editor UI change.
No file picker.
No image preview.
No blob write.
No IndexedDB write.
No backup write.
No backend upload.
No Google Drive sync.
No Anki mutation.
No frontend behavior beyond script loading.
No backend deploy.
No runtime mutation.
No service restart.
No DB write.
