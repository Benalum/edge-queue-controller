# Stage 17K-Y — Profile Anki Minimal Panel

Date: 2026-06-29

## Summary

Stage 17K-Y simplifies the Profile Anki panel.

The Profile page keeps only file-location help, the Choose File control, total deck/card counts, and per-deck card counts.

## Source changes

- Replaces the verbose Profile Anki render helpers with a minimal Profile Anki panel.
- Adds a `Where is my Anki file?` dropdown.
- Keeps the browser-local file chooser.
- Keeps deck count, total card count, and per-deck card count display.
- Removes selected file proof details, sample hash, file header, note type details, and old data ownership copy from the Profile Anki panel.
- Keeps strict Profile-only route guard.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
