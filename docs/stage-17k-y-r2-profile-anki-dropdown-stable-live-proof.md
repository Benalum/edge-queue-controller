# Stage 17K-Y-R2 — Profile Anki Dropdown Stable Live Proof

Date: 2026-06-29

## Summary

Stage 17K-Y-R2 was deployed and live-tested on the Profile page.

The Profile Anki panel is now minimal and the `Where is my Anki file?` dropdown stays open when clicked.

## Live result

Observed Profile Anki panel:

- Anki
- Choose your Anki collection file. APC reads deck names and card counts locally in this browser.
- Where is my Anki file?
- OS/location help:
  - Windows
  - macOS
  - Linux
  - Android / AnkiDroid
  - iPhone / iPad
- Choose Anki file
- Decks: 2
- Total cards: 3
- Deck card counts:
  - Anki Deck1: 2 card(s)
  - Anki Deck2: 1 card(s)

## Removed/no longer shown in the Profile Anki panel

- Selected file proof
- File status
- Sample SHA-256
- Local note type details
- Note types with notes
- Source type
- Clear local Anki proof

## Related cleanup state

- Study no longer shows Anki UI.
- Companion no longer shows Anki debug/local-card panels.
- Profile keeps the minimal Anki file/deck inventory UI.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was included.
