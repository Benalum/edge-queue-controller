# Stage 17K R16Z — Study card images disabled panel bind plan source-only

This stage adds a source-only disabled panel bind plan for the Study card image work.

Marker: APC_STUDY_CARD_IMAGES_DISABLED_PANEL_BIND_PLAN_R16Z_SOURCE_ONLY

The plan describes the disabled bridge between the staged image panel pieces and the future Study card editor panel. It does not load in index.html and it does not mount UI.

Safety posture:

- source-only
- no deploy
- no DOM mutation
- no event wiring
- no enabled controls
- no file picker
- no image preview
- no blob write
- no IndexedDB write
- no backup payload write
- no backend upload
- no Google Drive sync
- no Anki mutation

This stage is intended to be safe for Project Pilot Bridge because it has no interactive prompt, no SSH, no sudo, and no deploy step.
