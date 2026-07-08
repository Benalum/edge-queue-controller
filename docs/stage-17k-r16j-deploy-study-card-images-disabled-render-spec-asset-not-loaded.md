# stage-17k-r16j-deploy-study-card-images-disabled-render-spec-asset-not-loaded

Stage R16J deployed the disabled study-card image render spec static asset to VM200 but kept it not loaded by index.html.

Head before stage: 389fe710e45ba32a15bb2928a4e93268592ed1e4
Short head before stage: 389fe71
Timestamp: 20260708T152857Z
Tag: controller-stage-17k-r16j-deploy-study-card-images-disabled-render-spec-asset-not-loaded-2026-07-08

Scope:
- Deployed only privatepages/study-card-images-disabled-render-spec.js to /var/www/apc-wrapper-local/privatepages/study-card-images-disabled-render-spec.js.
- Created VM200 backup directory /var/www/apc-wrapper-local/apc-r16j-study-card-images-disabled-render-spec-asset-not-loaded-backup-20260708T152857Z.
- Did not edit index.html.
- Did not load the disabled render spec in the browser page.
- Did not mount UI.
- Did not add file picker, preview, blob storage, IndexedDB write, backup write, backend upload, Google Drive sync, or Anki mutation.

Proof summary:
- Public profile root returned 200.
- Public disabled render spec asset returned 200 and contained marker APC_STUDY_CARD_IMAGES_DISABLED_RENDER_SPEC_R16I_SOURCE_ONLY.
- Profile root did not include privatepages/study-card-images-disabled-render-spec.js.
- API guard remained system status 200, signed-out api/me 401, closed-beta signup 403, study decks 404.

Evidence directory:
docs/smoke/generated/stage-17k-r16j-deploy-study-card-images-disabled-render-spec-asset-not-loaded
