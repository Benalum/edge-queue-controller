# Stage 17J-R4C — Anki File Picker Only Live Proof

Date: 2026-06-28

## Summary

Stage 17J-R4C finalized the Profile Anki file picker UI by keeping only the user-selected Anki file picker/proof flow and removing the old manual manifest paste/status UI.

## Source checkpoint

- Commit: `b51b6e7`
- Tag: `controller-stage-17j-r4c-file-proof-visible-2026-06-28`

## VM200 deploy

- Live marker: `stage17j-r4c-file-proof-visible-20260628`
- VM200 backup: `/home/jkg76nid/apc-vm200-frontend-backups/stage17j-r4c-file-proof-visible-manual-20260628T203514Z`

## Browser proof

Browser check on `/profile` showed:

- `panel: true`
- `fileInput: true`
- `detailsOpen: true`
- `hasFileProof: true`
- `hasOldManifestTitle: false`
- `hasOldProfiles: false`
- `hasPasteManifest: false`

The selected Anki file proof is visible, including:

- File status
- File name
- Size
- Header
- Modified timestamp
- Sample SHA-256

## Safety notes

No backend deploy, DB change, nginx restart, cloudflared restart, Anki write, full-file storage, model call, worker activation, scheduler activation, or service mutation was performed.
