# stage-17k-r16aq-deploy-disabled-visible-panel-dom-template-source-index-no-ui-no-binding

Timestamp: 20260708T204812Z
HEAD before commit: f7a19c8341f430145cf25bcd0397e96ec9ab4a59
Short HEAD before commit: f7a19c8

## Result

R16AQ deployed the R16AP source-index load of the disabled visible study-card image panel DOM template to VM200 static hosting.

## Deployed files

- frontend/wrapper-ui/apc-wrapper-local/index.html
- privatepages/study-card-images-disabled-visible-panel.js
- privatepages/study-card-images-disabled-visible-panel-mount-adapter.js
- privatepages/study-card-images-disabled-visible-panel-dom-template.js

## Cache busts

- Visible panel and adapter: stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708
- DOM template: stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708

## Safety state

- Visible panel loaded by public index: true
- Visible panel adapter loaded by public index: true
- DOM template loaded by public index: true
- Script order visible before adapter before DOM template: true
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

## VM200 backup

/var/www/apc-wrapper-local/apc-r16aq-deploy-disabled-visible-panel-dom-template-source-index-backup-20260708T204812Z

## Public guard

- /api/system/status expected 200
- /api/me expected 401 signed-out
- /api/auth/register expected 403 closed beta
- /api/study/decks expected 404 local-only study guard
