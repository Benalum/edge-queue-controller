# Stage 17K-J — Anki Read-only Session Skeleton Live Proof

Date: 2026-06-28

## Summary

Stage 17K-J successfully deployed and proved the frontend-only Anki read-only session skeleton live on the Study page.

The skeleton is separate from the editable/backend-backed MyDecks study store.

It exposes:

- `window.APC_ANKI_READONLY_SESSION`
- a visible Study page panel
- selected Anki source validation
- local file re-select
- header-only Anki SQLite inspection
- in-memory-only skeleton session state

## Source checkpoint

- Commit: `0a0a69b`
- Tag: `controller-stage-17k-j-anki-readonly-session-skeleton-source-2026-06-28`

## VM200 deploy

- Deploy type: static frontend only
- Live marker: `stage17kj-anki-readonly-session-skeleton-20260628`
- Backup: `/home/jkg76nid/apc-vm200-frontend-backups/stage17kj-anki-readonly-session-skeleton-20260628T221217Z`

## Public HTTP proof

- `/study` returned HTTP 200
- `/privatepages/anki-readonly-session.js` contained `stage17kj-anki-readonly-session-skeleton-20260628`
- `/privatepages/anki-readonly-session.js` contained `APC_ANKI_READONLY_SESSION`

## Browser proof: skeleton loaded

Browser console proof on `/study` showed:

- `apiVersion: stage17kj-anki-readonly-session-skeleton-20260628`
- `panel: true`
- `hasPanelText: true`
- `hasNoBackendCopy: true`
- `hasNoCardExtractionCopy: true`
- `selection_source_type: anki_browser_local`
- `selected_deck_name: Anki Deck1`
- `selected_deck_id: 1`
- initial `status: idle`

## Browser proof: file selected and skeleton session started

After selecting `collection.anki2` and clicking Start local Anki skeleton session, browser snapshot showed:

- `version: stage17kj-anki-readonly-session-skeleton-20260628`
- `selection_source_type: anki_browser_local`
- `selected_deck_name: Anki Deck1`
- `selected_deck_id: 1`
- `status: skeleton_active`
- `active: true`
- `selected_file_name: collection.anki2`
- `selected_file_size: 139264`
- `selected_file_header_kind: sqlite-anki-collection`
- `reviewed_count: 0`
- `card_count_in_memory: 0`
- `message: Skeleton session started. No card text has been extracted or stored yet.`

## Privacy flags

The live snapshot showed:

- `browser_memory_only: true`
- `card_text_localstorage_allowed: false`
- `backend_calls_allowed: false`
- `anki_write_allowed: false`
- `mydecks_writeback_allowed: false`

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.

No Anki card text was extracted in this skeleton stage.

No Anki card text was stored in localStorage.

No backend API call is allowed by the skeleton.
