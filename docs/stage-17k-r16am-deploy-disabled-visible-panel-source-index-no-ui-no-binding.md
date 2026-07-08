# stage-17k-r16am-deploy-disabled-visible-panel-source-index-no-ui-no-binding

Timestamp: 20260708T203321Z
HEAD before commit: 478206586f2daed8f8b5a576af83bd8f580c4fde
Short HEAD before commit: 4782065

## Result

R16AM deployed the R16AL source index load of the disabled visible study-card image panel assets to VM200 static hosting.

## Deployed files

- frontend/wrapper-ui/apc-wrapper-local/index.html
- privatepages/study-card-images-disabled-visible-panel.js
- privatepages/study-card-images-disabled-visible-panel-mount-adapter.js

## Cache bust

stage17k-r16al-load-disabled-visible-panel-source-index-source-only-20260708

## Safety state

- Visible panel loaded by public index: true
- Visible panel adapter loaded by public index: true
- Visible panel script before adapter: true
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

/var/www/apc-wrapper-local/apc-r16am-deploy-disabled-visible-panel-source-index-backup-20260708T203321Z

## Public guard

- /api/system/status expected 200
- /api/me expected 401 signed-out
- /api/auth/register expected 403 closed beta
- /api/study/decks expected 404 local-only study guard
