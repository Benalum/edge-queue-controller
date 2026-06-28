# Stage 17K-H — Study Source Selector UI Live Proof

Date: 2026-06-28

## Summary

Stage 17K-H successfully proved the Study source selector live in the browser.

The Study page now exposes two source choices:

- Study with Anki
- Study with MyDecks

The Anki choice uses the browser-local Anki summary created by the Profile Anki picker.

## Source checkpoint

- Commit: `7a00c69`
- Tag: `controller-stage-17k-h-study-source-selector-ui-source-2026-06-28`

## Live marker

- `stage17kh-study-source-selector-ui-20260628`

## Browser proof: selector loaded

Browser console proof on `/study` showed:

- `apiVersion: stage17kh-study-source-selector-ui-20260628`
- `selectorPanel: true`
- `hasStudyWithAnki: true`
- `hasStudyWithMyDecks: true`
- `hasLocalOnlyCopy: true`
- `ankiSummaryAvailable: true`
- Anki decks available: `2`
- Initial selection: `null`

The visible Study page included:

- `Study source`
- `Anki stays browser-local and read-only`
- `Study with Anki`
- `Use Anki Deck1 · 2 cards`
- `Use Anki Deck2 · 1 cards`
- `Study with MyDecks`
- `Privacy and permission boundary`

## Browser proof: Anki deck selected

After selecting `Anki Deck1`, browser console proof showed:

- `clicked: true`
- `apiVersion: stage17kh-study-source-selector-ui-20260628`
- `sourceType: anki_browser_local`
- `deckName: Anki Deck1`
- `readOnly: true`
- `canEdit: false`
- `canCreate: false`
- `canDelete: false`
- `canFlag: false`
- `canWriteAnki: false`
- `canUploadAnkiContent: false`

The browser-local selection object included:

- `source_type: anki_browser_local`
- `source_label: Study with Anki`
- `deck_id: 1`
- `deck_name: Anki Deck1`
- `card_count: 2`

## Privacy and permission boundary

The Anki selector stores only a browser-local source choice in localStorage.

It does not call the backend.

It does not upload Anki deck names, card text, answers, tags, media, or per-card review history.

It does not write to Anki.

It keeps Anki separated from the existing editable/backend-backed MyDecks study store.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.
