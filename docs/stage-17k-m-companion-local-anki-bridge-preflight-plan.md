# Stage 17K-M — Companion Local Anki Bridge Preflight Plan

Date: 2026-06-28

## Summary

Stage 17K-M prepares the next safe bridge between Companion and the browser-local Anki review session.

The goal is for Companion UI code to detect the current local Anki card shape from browser memory only.

This stage is preflight and planning only.

It does not patch Companion behavior yet.

## Current source checkpoint

- HEAD before Stage 17K-M plan: `c128284`
- Prior live proof tag: `controller-stage-17k-l-anki-local-review-loop-live-proof-2026-06-28`

## Proven Anki state

The browser-local Anki adapter is live and proved:

- local file picker reads `collection.anki2` in browser
- selected deck `Anki Deck1` can be loaded into memory
- Basic card question/answer can be shown locally
- reveal/right/wrong/stop works locally
- stop clears in-memory cards
- no Anki file upload
- no Anki write
- no backend API call from the Anki adapter
- no card text saved to repo docs

## Planned Companion bridge

The first Companion bridge must be read-only and browser-local.

Allowed:

- read `window.APC_ANKI_READONLY_SESSION.snapshot()`
- read `window.APC_ANKI_READONLY_SESSION.currentCard()`
- derive a non-persistent current card shape for display
- show local-only status in Companion UI
- show that the active source is `anki_browser_local`
- show deck name and note type only if already visible in the local page
- allow user to ask Companion to look at the current visible card locally

Forbidden for this bridge:

- backend API calls containing Anki card text
- model calls containing Anki card text
- saving Anki card text to localStorage
- saving Anki card text to repo docs
- writing to Anki
- flagging Anki cards
- editing Anki cards
- deleting Anki cards
- creating Anki cards
- uploading Anki files
- MyDecks writeback for Anki-sourced cards

## Proposed API boundary

Companion should consume a narrow local object such as:

```js
{
  source_type: "anki_browser_local",
  active: true,
  deck_name: "...",
  note_type_name: "...",
  has_question: true,
  has_answer: true,
  reviewed_count: 0,
  correct_count: 0,
  wrong_count: 0,
  privacy: {
    browser_memory_only: true,
    backend_calls_allowed: false,
    anki_write_allowed: false
  }
}
```

The first bridge should avoid sending `question` and `answer` to any backend/model path.

## Implementation recommendation

Next source patch should add a small browser-local bridge script, separate from existing backend-backed Companion send paths:

- `privatepages/companion-local-anki-bridge.js`

The bridge should expose:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.version`
- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.snapshot()`
- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.currentCardShape()`

It should not call:

- `fetch`
- `XMLHttpRequest`
- `sendBeacon`
- `/api/*`

It should not persist card text.

## Inventory

Preflight inventory was written to:

- `/tmp/stage17k-m-companion-local-anki-bridge-inventory.txt`

## Safety

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.

Only repo docs and smoke are added in this preflight stage.
