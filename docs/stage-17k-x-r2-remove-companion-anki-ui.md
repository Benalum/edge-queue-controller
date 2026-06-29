# Stage 17K-X-R2 — Remove Companion Local Card UI

Date: 2026-06-29

## Summary

Stage 17K-X-R2 removes the visible local-card bridge and local-card session controls from the Companion page.

This removes the Companion panels at the source. It is not a CSS hide.

## Source changes

- Replaces `companion-local-anki-bridge.js` with a no-UI compatibility module.
- Replaces `anki-readonly-session.js` with a no-UI compatibility module.
- Both modules remove any existing panels if they are present.
- Both modules keep safe compatibility APIs so older callers do not throw.
- Cache-busts both scripts in `index.html`.

## Removed from Companion UI

- Companion local Anki bridge.
- Browser-memory bridge only.
- Describe current local Anki card shape.
- Mount local Anki session controls.
- Use current Anki card in Companion study.
- Anki read-only session.
- Re-select Anki file for this browser session.
- Load selected Anki deck into memory.
- Reveal answer / Right / Wrong / Stop buttons.

## Preserved

- Main Sol chat UI.
- Voice controls.
- Browser voice controls.
- Companion study/deck capabilities that are not local-file specific.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
