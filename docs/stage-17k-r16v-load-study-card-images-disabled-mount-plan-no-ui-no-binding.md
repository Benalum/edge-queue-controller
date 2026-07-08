# stage-17k-r16v-load-study-card-images-disabled-mount-plan-no-ui-no-binding

Timestamp: 20260708T183200Z
HEAD before commit: 95d43c8b7d1d4c9eeed678cf654eaf50d556d000
Short HEAD before commit: 95d43c8

## Result

R16V loads the disabled study card image mount plan script in index.html with cache bust stage17k-r16v-load-disabled-mount-plan-no-ui-no-binding-20260708.

The first R16V attempt reached source smoke and then failed during VM200 deploy because remote sudo required a terminal. This finish run used ssh -tt for the VM200 sudo step, completed deployment, and recorded fresh public smoke evidence.

## Safety

- Source asset: privatepages/study-card-images-disabled-mount-plan.js
- Marker: APC_STUDY_CARD_IMAGES_DISABLED_MOUNT_PLAN_R16S_SOURCE_ONLY
- Deployed: true
- Loaded by index: true
- Mounted: false
- Button rendered: false
- Controls enabled: false
- File picker opened: false
- Image preview rendered: false
- Blob stored: false
- IndexedDB write: false
- Backup payload write: false
- Backend upload: false
- Google Drive sync: false
- Anki mutation: false

## VM200 backup

/var/www/apc-wrapper-local/apc-r16v-load-disabled-mount-plan-no-ui-no-binding-backup-20260708T183200Z

## Browser proof required next

After deployment, hard refresh https://buddieswhostudy.com/profile and verify the mount plan is loaded on window while no image UI or write path exists.
