# Stage 17K R16AC — Study Card Images Disabled Panel HTML Preview Renderer Source-Only

This stage adds a pure, inert HTML preview renderer for the future optional study-card image panel.

The renderer is source-only and PPB-runnable. It is not loaded by `index.html`, not deployed, not mounted, and not writable.

Safety posture:

- no interactive prompt
- no SSH
- no sudo
- no deploy
- no DOM mounting
- no click binding
- no file picker
- no image preview rendering in the live page
- no blob storage
- no IndexedDB write
- no backup payload write
- no backend upload
- no Google Drive sync
- no Anki mutation

The renderer only returns an escaped HTML string for a disabled question-image and answer-image panel preview. It does not insert the HTML into the page.
