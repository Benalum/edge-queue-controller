# Stage 17K-F — Browser-local Anki Deck UI Live Proof

Date: 2026-06-28

## Summary

Stage 17K-F successfully deployed the browser-local Anki deck extraction UI to VM200 static frontend and proved it live in the browser.

The Profile Anki panel now loads the same-origin vendored sql.js assets and parses the user-selected `collection.anki2` file locally in the browser.

## Source checkpoint

- Commit: `bac9b71`
- Tag: `controller-stage-17k-f-browser-local-anki-deck-ui-source-2026-06-28`

## VM200 deploy

- Deploy type: static frontend only
- Live marker: `stage17kf-browser-local-deck-ui-20260628`
- Backup: `/home/jkg76nid/apc-vm200-frontend-backups/stage17kf-browser-local-anki-deck-ui-r3-20260628T215339Z`

## Public HTTP proof

- `/profile` returned HTTP 200
- `/vendor/sqljs/sql-wasm.wasm` returned HTTP 200
- WASM content type: `application/wasm`
- WASM content length: `652953`

## Browser proof

Browser console proof on `/profile` after selecting `collection.anki2` showed:

- `apiVersion: stage17kf-browser-local-deck-ui-20260628`
- `panel: true`
- `fileInput: true`
- `hasLocalDecks: true`
- `hasAnkiDeck1: true`
- `hasAnkiDeck2: true`
- `hasNoUploadCopy: true`
- `localSummary.status: extracted`
- `localSummary.source_type: anki_browser_local`

The visible Profile text showed:

- `Local Anki decks`
- `Anki Deck1`
- `2 cards / 2 notes`
- `Anki Deck2`
- `1 cards / 1 notes`
- `Deck names, card text, tags, and media are not sent to the server.`

## Same-origin browser resources

The browser proof showed these resources loaded:

- `https://alexhartel.com/privatepages/anki-manifest-panel.js?v=stage17kf-browser-local-deck-ui-20260628`
- `https://alexhartel.com/vendor/sqljs/sql-wasm.js`
- `https://alexhartel.com/vendor/sqljs/sql-wasm.wasm`

No CDN resource was used.

## Privacy proof

The live UI states that Anki is browser-local and read-only.

The browser-local summary uses:

- `source_type: anki_browser_local`

The source implementation records privacy flags for:

- no uploads performed
- no server-saved Anki content
- no Anki file modification
- no deck names sent to server
- no card text sent to server
- no media sent to server

## Note

The quick visible-text proof returned `hasBasic: false` because note type details are inside a collapsed details section. This does not block the deck extraction proof. The primary live proof for this stage is local deck extraction and same-origin browser parsing.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.
