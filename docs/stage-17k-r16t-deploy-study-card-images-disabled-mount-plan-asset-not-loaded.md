# stage-17k-r16t-deploy-study-card-images-disabled-mount-plan-asset-not-loaded

Result: R16T deployed the disabled study-card image mount plan static asset to VM200 while keeping it not loaded by index.html, not mounted, and not writable.

Source checkpoint:
- Head: 550fb741deea76a112bbf1f290096217bfa5d463
- Short head: 550fb74
- Source asset: frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-mount-plan.js
- Marker: APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY

Scope:
- Deployed only study-card-images-disabled-mount-plan.js to VM200 static privatepages.
- Did not patch index.html.
- Did not mount UI.
- Did not render buttons.
- Did not enable controls.
- Did not open file pickers.
- Did not render image previews.
- Did not write blobs, IndexedDB, backup payloads, backend uploads, Google Drive sync, or Anki/source files.

VM200 backup:
/var/www/apc-wrapper-local/apc-r16t-study-card-images-disabled-mount-plan-asset-not-loaded-backup-20260708T162255Z

Evidence:
docs/smoke/generated/stage-17k-r16t-deploy-study-card-images-disabled-mount-plan-asset-not-loaded/
