# stage-17k-r16ah-study-card-images-disabled-panel-source-bundle-manifest-source-only

Status: complete.

This stage adds a source-only disabled Study card image panel source-bundle manifest.
It records the R16X through R16AG panel helper assets as a future deploy/load bundle, but does not deploy, load, mount, bind, render, enable controls, open a picker, store blobs, write backup payloads, upload to a backend, sync to Google Drive, or mutate Anki data.

- Source asset: `privatepages/study-card-images-disabled-panel-source-bundle-manifest.js`
- Marker: `APC_STUDY_CARD_IMAGES_DISABLED_PANEL_SOURCE_BUNDLE_MANIFEST_R16AH_SOURCE_ONLY`
- Smoke: `ops/smoke/check-stage-17k-r16ah-study-card-images-disabled-panel-source-bundle-manifest-source-only.sh`
- Evidence: `docs/smoke/generated/stage-17k-r16ah-study-card-images-disabled-panel-source-bundle-manifest-source-only`
- PPB runnable: true
- Interactive required: false
- Remote SSH: false
- Remote sudo: false
- Deploy: false

Safety invariants preserved:

- Study image data remains browser-local only.
- No server image upload path is introduced.
- No Google Drive sync path is activated.
- No Anki/APKG/profile mutation path is introduced.
- No image picker, preview, blob storage, or backup write is bound.
- Existing public index remains unchanged and does not load this R16AH bundle manifest.
