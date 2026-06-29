# Stage 17K-W — Remove Anki from Study Page

Date: 2026-06-28

## Summary

Stage 17K-W removes the Anki UI from the Study page at the source.

This is not a CSS hide or display bandaid.

The Study page now renders only the APC-native MyDecks study source panel.

Anki browser-local functionality remains available for Profile/Companion flows.

## Source changes

- Rewrote `study-source-selector.js` as a Study-page MyDecks-only selector.
- Removed Study Anki source picker UI.
- Removed Study Anki deck rows.
- Removed Study Anki selection action.
- Changed `anki-readonly-session.js` so its panel mounts only on Companion, not Study.
- Cache-busted both private frontend scripts in `index.html`.

## Removed from Study UI

- Study with Anki
- Selected Anki deck
- Anki read-only session
- Re-select local Anki file
- Load selected local deck into memory
- Reveal answer / Right / Wrong / Stop Anki buttons

## Preserved

- Profile local Anki file summary flow remains script-loadable.
- Companion local Anki bridge remains script-loadable.
- Companion consented current-card handoff remains script-loadable.
- No backend deploy or service restart is required.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
