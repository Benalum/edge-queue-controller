# Stage 17K R16AG — Study card images disabled panel load-order contract source-only

This stage adds a source-only load-order contract for the disabled study-card image panel helpers.

The contract documents the expected helper order before any visible UI is mounted. It is intentionally inert:

- no deploy
- no index load
- no visible panel
- no enabled controls
- no file picker
- no image preview
- no blob or IndexedDB write
- no backup write
- no backend upload
- no Google Drive sync
- no Anki mutation

The script is PPB-runnable because it does not require interactive input, SSH, sudo, or a browser step.

## Evidence

- Stage: `stage-17k-r16ag-study-card-images-disabled-panel-load-order-source-only`
- Timestamp: `20260708T190648Z`
- HEAD before: `ede0c5d834192dafb1fbcf18388ce88ff8e2b50e`
- Short HEAD before: `ede0c5d`
- Asset: `frontend/wrapper-ui/apc-wrapper-local/privatepages/study-card-images-disabled-panel-load-order-contract.js`
- Marker: `APC_STUDY_CARD_IMAGES_DISABLED_PANEL_LOAD_ORDER_CONTRACT_R16AG_SOURCE_ONLY`
- Smoke: `ops/smoke/check-stage-17k-r16ag-study-card-images-disabled-panel-load-order-source-only.sh`
