# R16BO deploy disabled visible panel mount activation request source index

Stage: stage-17k-r16bo-deploy-disabled-visible-panel-mount-activation-request-source-index-no-ui-no-binding
Timestamp UTC: 20260710T173324Z
HEAD before: 6fc0c6cea2c8114a8d74d1eca3e8c598ba4e3305
Short HEAD before: 6fc0c6ce

This stage deployed the R16BN source index load for the disabled visible Study card image panel mount activation request to VM200 static frontend.

Safety result:
- Deploy: true
- Interactive SSH sudo: true
- Visible panel asset loaded by public index: true
- Mount activation request asset loaded by public index: true
- Executed: false
- Mounted: false
- Controls enabled: false
- File picker opened: false
- Image preview rendered: false
- Client write: false
- IndexedDB write: false
- Backup payload write: false
- Backend upload: false
- Google Drive sync: false
- Anki mutation: false

Public guard result:
- /api/system/status expected 200
- /api/me expected 401 while signed out
- /api/auth/register expected 403 closed beta
- /api/study/decks expected 404 removed private Study backend persistence

Backup directory on VM200:
/var/www/apc-wrapper-local/apc-r16bo-deploy-disabled-visible-panel-mount-activation-request-source-index-backup-20260710T173324Z
