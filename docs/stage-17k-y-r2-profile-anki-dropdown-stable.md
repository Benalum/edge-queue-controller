# Stage 17K-Y-R2 — Profile Anki Dropdown Stable

Date: 2026-06-29

## Summary

Stage 17K-Y-R2 fixes the Profile Anki `Where is my Anki file?` details dropdown closing immediately after click.

Root cause: `anki-manifest-panel.js` still remounted the panel on every document click. Clicking the details arrow opened the browser-native dropdown, then the script re-rendered the panel and reset it closed.

## Source changes

- Removes the document-wide click remount listener from `anki-manifest-panel.js`.
- Preserves the file-location help dropdown open state across intentional panel re-renders.
- Cache-busts `anki-manifest-panel.js` in `index.html`.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
