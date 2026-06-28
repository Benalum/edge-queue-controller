# Stage 17K-Q — Companion Local Anki Current Card Shape Command Live Proof

Date: 2026-06-28

## Summary

Stage 17K-Q successfully proved the Companion local Anki current-card-shape command live on the Companion page.

The command is exposed through:

- `window.APC_COMPANION_LOCAL_ANKI_BRIDGE.currentCardShapeCommand()`

The command returns safe local Anki status, shape, and privacy information.

It does not return Anki question text.

It does not return Anki answer text.

It does not call the backend.

It does not call a model.

It does not write to Anki.

## Source checkpoint

- Commit: `bbe3c9f`
- Tag: `controller-stage-17k-q-companion-local-anki-card-shape-command-2026-06-28`

## Live marker

- `stage17kq-companion-local-anki-current-card-shape-command-20260628`

## Browser proof

Browser console proof on `/companion` returned:

- `ok: true`
- `bridgeVersion: stage17kq-companion-local-anki-current-card-shape-command-20260628`
- `command: current_anki_card_shape`
- `panelHasButton: true`
- `panelHasOutput: true`
- `doesNotReturnQuestionText: true`
- `doesNotReturnAnswerText: true`
- `noBackendAllowed: true`
- `noModelAllowed: true`
- `noAnkiWriteAllowed: true`

## Command message proof

The command message preview included:

- `Local Anki bridge status:`
- `source: anki_browser_local`
- `status: idle`
- `active: no`
- `deck: Anki Deck1`
- `cards in memory: 0`
- `current card shape: none`
- `question present: no`
- `answer present: no`
- `note type: none`
- `Privacy: this command does not return card question text or answer text, and it does not call a backend or model.`

## Shape proof

The returned shape object contained only shape fields.

It did not contain a `question` field.

It did not contain an `answer` field.

The idle proof shape was:

- `present: false`
- `has_question: false`
- `has_answer: false`
- `deck_name: Anki Deck1`
- `note_type_name: empty`

## Resource proof

The browser loaded:

- `/privatepages/anki-readonly-session.js?v=stage17kk-anki-basic-memory-session-20260628-r4-status-repair`
- `/privatepages/companion-local-anki-bridge.js?v=stage17kq-companion-local-anki-current-card-shape-command-20260628`

## Notes

`status: idle`, `cards in memory: 0`, and `current card shape: none` are acceptable for this live proof.

This stage proves that the Companion command exists, renders in the panel, returns a safe local-only message, and preserves the privacy boundary even without an active card in browser memory.

## Privacy boundary

The Companion local Anki command returns only status, counters, and shape information.

It does not return Anki question text.

It does not return Anki answer text.

It does not allow backend calls.

It does not allow model calls.

It does not allow Anki writes.

It does not allow MyDecks writeback for Anki-sourced cards.

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed for this proof.

The proof used already-deployed static frontend files only.

No Anki question text or answer text was saved to repo docs.
