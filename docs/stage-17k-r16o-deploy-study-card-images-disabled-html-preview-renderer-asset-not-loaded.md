# stage-17k-r16o-deploy-study-card-images-disabled-html-preview-renderer-asset-not-loaded

## Result

R16O deployed the disabled study-card image HTML preview renderer static asset to VM200 while keeping it not loaded by `index.html`, not mounted, and not writable.

## Source checkpoint

- Head: `ea2cd6a7c2bee4ccd8acd7115b07f03ca2af75ba`
- Short head: `ea2cd6a`
- Source asset: `frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-html-preview-renderer.js`
- Marker: `APC_STUDY_CARD_IMAGES_DISABLED_HTML_PREVIEW_RENDERER_R16N_SOURCE_ONLY`

## Scope

- Deployed only `study-card-images-disabled-html-preview-renderer.js` to VM200 static privatepages.
- Did not patch `index.html`.
- Did not mount UI.
- Did not render buttons.
- Did not open file pickers.
- Did not render image previews.
- Did not write blobs, IndexedDB, backup payloads, backend uploads, Google Drive sync, or Anki/source files.

## VM200 backup

`/var/www/apc-wrapper-local/apc-r16o-study-card-images-disabled-html-preview-renderer-asset-not-loaded-backup-20260708T155445Z`

## Evidence

Generated evidence is under:

`docs/smoke/generated/stage-17k-r16o-deploy-study-card-images-disabled-html-preview-renderer-asset-not-loaded/`
