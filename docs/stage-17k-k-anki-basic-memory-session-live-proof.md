# Stage 17K-K — Anki Basic Memory Session Live Proof

Date: 2026-06-28

## Summary

Stage 17K-K successfully deployed and proved the browser-local Anki Basic memory session live on the Study page.

The adapter can load Basic-style Anki cards from the selected local Anki deck into JavaScript memory only.

This live proof intentionally does not record Anki card question text or answer text.

## Source checkpoints

- Stage 17K-K source commit: `2c822f9`
- Stage 17K-K source tag: `controller-stage-17k-k-anki-basic-memory-session-source-2026-06-28`
- Stage 17K-K-R2 repair commit: `aa8831c`
- Stage 17K-K-R2 repair tag: `controller-stage-17k-k-r2-anki-file-memory-handoff-repair-2026-06-28`

## Live marker

- `stage17kk-anki-basic-memory-session-20260628`

## Browser proof

Browser proof on `/study` after selecting `Anki Deck1`, re-selecting `collection.anki2`, and clicking `Load selected Anki deck into memory` showed:

- `apiVersion: stage17kk-anki-basic-memory-session-20260628`
- `panel: true`
- `hasMemoryCopy: true`
- `hasNoBackendCopy: true`
- `snapshot.status: active`
- `selection_source_type: anki_browser_local`
- `selected_deck_name: Anki Deck1`
- `selected_deck_id: 1`
- `currentCardShape.hasQuestion: true`
- `currentCardShape.hasAnswer: true`
- `currentCardShape.deckName: Anki Deck1`
- `currentCardShape.noteTypeName: Basic`

## Same-origin resources

The browser loaded:

- `/privatepages/anki-readonly-session.js?v=stage17kk-anki-basic-memory-session-20260628`
- `/vendor/sqljs/sql-wasm.js`
- `/vendor/sqljs/sql-wasm.wasm`

No CDN resource was used.

## Privacy boundary

The proof confirms that Anki card data is loaded into JavaScript memory for the active browser page.

The proof document deliberately omits:

- card question text
- card answer text
- card IDs
- note IDs
- media filenames
- media data
- per-card review history

The adapter source keeps privacy flags for:

- `browser_memory_only: true`
- `card_text_localstorage_allowed: false`
- `backend_calls_allowed: false`
- `anki_write_allowed: false`
- `mydecks_writeback_allowed: false`

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.

No Anki card text was saved to repo docs.

No Anki card text was intentionally saved to localStorage.

No backend API call is allowed by this adapter.
