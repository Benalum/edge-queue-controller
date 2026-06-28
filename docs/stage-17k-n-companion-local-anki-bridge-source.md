# Stage 17K-N — Companion Local Anki Bridge Source

Date: 2026-06-28

## Summary

Stage 17K-N adds a separate Companion local Anki bridge source file.

The bridge lets Companion UI detect the current browser-local Anki card shape from JavaScript memory only.

It does not return Anki card question text or answer text.

It does not send anything to a backend or model path.

## Added file

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js`

## Exposed API

The bridge exposes:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.version`
- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.snapshot()`
- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.currentCardShape()`
- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.renderPanel()`

## Data returned

The bridge can return:

- source type
- adapter status
- active true/false
- selected deck name
- selected deck id
- cards in memory count
- reviewed/correct/wrong counters
- current card shape:
  - card present true/false
  - question present true/false
  - answer present true/false
  - note type name
  - question length
  - answer length

## Data not returned

The bridge does not return:

- Anki question text
- Anki answer text
- Anki media data
- Anki card ID
- Anki note ID
- Anki per-card review history

## Privacy flags

The bridge advertises:

- `browser_memory_only: true`
- `card_text_returned_by_bridge: false`
- `backend_calls_allowed: false`
- `model_calls_allowed: false`
- `anki_write_allowed: false`
- `mydecks_writeback_allowed: false`

## Safety

This is a source-only stage.

No frontend deploy, backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation is included.
