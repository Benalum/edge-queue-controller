# Stage 17K R16AA — Study Card Images Disabled Panel Composition Plan Source-Only

This stage adds a source-only disabled panel composition plan for optional study-card images.

## Safety

- PPB-runnable: yes.
- Interactive input: no.
- Remote SSH: no.
- Remote sudo: no.
- Deploy: no.
- Loaded by `index.html`: no.
- Mounted UI: no.
- Image buttons: not rendered.
- File picker: not opened.
- Image preview: not rendered.
- Blob or IndexedDB write: no.
- Backup payload write: no.
- Backend upload: no.
- Google Drive sync: no.
- Anki mutation: no.

## Added source

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-composition-plan.js`

The composition plan joins the staged disabled image render, preview, mount, bridge, integration-gate, and bind-plan concepts into a metadata-only plan for the question and answer sides. It does not touch the DOM and does not bind clicks.

## Marker

`APC_STUDY_CARD_IMAGES_DISABLED_PANEL_COMPOSITION_PLAN_R16AA_SOURCE_ONLY`
