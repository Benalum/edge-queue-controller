# stage-17k-r16al-load-disabled-visible-panel-source-index-source-only

R16AL loads the disabled visible study-card image panel source assets into the source  only.

Checkpoint before commit:  / .

## Scope

- PPB-runnable: yes.
- Interactive required: no.
- Remote SSH/sudo: no.
- Deploy: no.
- Live site changed: no.
- Source change: source  loads exactly two disabled visible panel assets with cache bust .

## Safety gates

- The visible panel script loads before the mount adapter script.
- The smoke verifies exact source-index counts and load order.
- The panel remains disabled/inert.
- No file picker, image preview, client write, backup payload write, backend upload, Google Drive sync, or Anki mutation is enabled.

Marker: .
