# stage-17k-r16au-deploy-disabled-visible-panel-slot-resolver-source-index-no-ui-no-binding

Timestamp: 20260708T210503Z
HEAD before commit: c1efa39be2843563716badbdd9eacf00fd5f8ec3
Short HEAD before commit: c1efa39

## Result

R16AU deployed the R16AT source-index load of the disabled visible study-card image panel slot resolver to VM200 static hosting.

## Deployed files

- frontend/wrapper-ui/apc-wrapper-local/index.html
- privatepages/study-card-images-disabled-visible-panel.js
- privatepages/study-card-images-disabled-visible-panel-mount-adapter.js
- privatepages/study-card-images-disabled-visible-panel-dom-template.js
- privatepages/study-card-images-disabled-visible-panel-slot-resolver.js

## Cache busts

- Visible panel and adapter: stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708
- DOM template: stage17k-r16ap-load-disabled-visible-panel-dom-template-source-index-source-only-20260708
- Slot resolver: stage17k-r16at-load-disabled-visible-panel-slot-resolver-source-index-source-only-20260708

## Safety state

- Visible panel loaded by public index: true
- Visible panel adapter loaded by public index: true
- DOM template loaded by public index: true
- Slot resolver loaded by public index: true
- Script order visible before adapter before DOM template before slot resolver: true
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

/var/www/apc-wrapper-local/apc-r16au-deploy-disabled-visible-panel-slot-resolver-source-index-backup-20260708T210503Z

## Public guard

- /api/system/status expected 200
- /api/me expected 401 signed-out
- /api/auth/register expected 403 closed beta
- /api/study/decks expected 404 local-only study guard
