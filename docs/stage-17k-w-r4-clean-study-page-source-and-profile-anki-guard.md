# Stage 17K-W-R4 — Clean Study Page Source and Profile Anki Guard

Date: 2026-06-29

## Summary

Stage 17K-W-R4 removes the Study source card from Study and fixes the Profile Anki manifest route guard.

The Study source selector is now a no-UI compatibility module that removes `#apc-study-source-selector` instead of rendering a card.

The Anki manifest panel remains available for Profile, but it no longer treats generic `.profile-card` elements as proof that the current route is Profile.

## Removed from Study UI

- Study source
- Study uses APC-native MyDecks on this page.
- No native study source selected yet.
- Study with MyDecks
- Use MyDecks
- Privacy and permission boundary
- Clear source selection
- Anki file picker
- Local Anki decks

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
