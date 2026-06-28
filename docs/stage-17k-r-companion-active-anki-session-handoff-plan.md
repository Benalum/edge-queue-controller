# Stage 17K-R — Companion Active Anki Session Handoff Plan

Date: 2026-06-28

## Summary

Stage 17K-R records the safe handoff plan for making an active browser-local Anki session usable from Companion.

The current Companion local Anki bridge can report local Anki status and current-card shape safely.

The next goal is to let Companion attach to or start a browser-local Anki session without routing Anki cards through the MyDecks edit/delete/flag/write flows.

## Preflight checkpoint

Stage 17K-R preflight inventory was run at repo checkpoint:

- HEAD: `4709542`
- Current bridge marker: `stage17kq-companion-local-anki-current-card-shape-command-20260628`

## Current browser-local Anki components

The Anki read-only session adapter already exposes:

- `window.APC_ANKI_READONLY_SESSION`
- `renderPanel()`
- `snapshot()`
- `currentCard()`
- `revealAnswer()`
- `stopSession()`

The Companion local Anki bridge already exposes:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE`
- `snapshot()`
- `currentCardShape()`
- `currentCardShapeCommand()`
- `renderPanel()`

The Study source selector already records Anki as:

- `source_type: anki_browser_local`
- `browser_local_only: true`
- `can_write_anki: false`
- `can_upload_anki_content: false`

## Important boundary from preflight

The existing `companion.js` MyDecks path is not safe for Anki cards.

That path can expose card front/back text and supports card create/edit/delete/flag flows.

Therefore Anki must remain on a separate Companion bridge path.

Do not merge Anki cards into `APC_STUDY_STORE`.

Do not route Anki cards through MyDecks command handlers.

Do not store Anki question text or answer text in Companion chat messages, localStorage, backend, DB, or model calls.

## Required handoff design

The safe handoff should add a Companion-side local-only Anki session area that can:

1. Show whether the Anki read-only adapter is present.
2. Show whether an Anki deck has been selected locally.
3. Let the user mount or open the existing browser-local Anki loader from Companion.
4. Let the user load the selected Anki deck into JavaScript memory.
5. Let Companion describe only current-card shape/status/counters.
6. Keep card question text and answer text inside the read-only Anki session adapter UI only.
7. Keep all Anki data browser-local.
8. Keep all writes disabled for Anki.

## Allowed data through Companion bridge

Allowed:

- source type
- active true/false
- selected deck name
- selected deck id
- card count in memory
- reviewed count
- correct count
- wrong count
- current index
- card present true/false
- question present true/false
- answer present true/false
- note type name
- question length
- answer length
- privacy flags

Forbidden:

- question text
- answer text
- card id
- note id
- media filename
- media data
- tags
- per-card timing history
- transcript
- backend calls
- model calls
- Anki writes
- MyDecks writeback for Anki cards

## Proposed next patch

Stage 17K-S should add a local-only Companion Anki session mount.

The mount should:

- stay in `companion-local-anki-bridge.js`
- not patch `companion.js` MyDecks study commands yet
- not add backend calls
- not add model calls
- not add localStorage writes for card content
- not expose Anki question text or answer text through the bridge
- call existing Anki read-only adapter APIs where possible
- provide visible UI copy explaining that the user may need to re-select the Anki file because browser File objects cannot safely persist across hard refreshes or full route reloads

## Safety

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included in this plan.

This is a docs/smoke-only stage.
