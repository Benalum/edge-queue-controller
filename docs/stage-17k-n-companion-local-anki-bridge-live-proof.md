# Stage 17K-N — Companion Local Anki Bridge Live Proof

Date: 2026-06-28

## Summary

Stage 17K-N successfully proved the Companion local Anki bridge live in the browser.

The bridge reads the browser-local Anki adapter state from JavaScript memory and returns only a safe current-card shape.

This proof intentionally does not record Anki question text or answer text.

## Source checkpoint

- Commit: `9cd94cd`
- Tag: `controller-stage-17k-n-companion-local-anki-bridge-source-2026-06-28`

## Live marker

- `stage17kn-companion-local-anki-bridge-source-20260628`

## Browser proof

Browser console proof showed:

- `version: stage17kn-companion-local-anki-bridge-source-20260628`
- `bridge_ready: true`
- `anki_adapter_present: true`
- `source_type: anki_browser_local`
- `status: active`
- `active: true`
- `selected_deck_name: Anki Deck1`
- `selected_deck_id: 1`
- `card_count_in_memory: 2`
- `reviewed_count: 0`
- `correct_count: 0`
- `wrong_count: 0`
- `current_index: 0`

## Current card shape proof

The bridge returned current card shape only:

- `current_card_shape.present: true`
- `current_card_shape.has_question: true`
- `current_card_shape.has_answer: true`
- `current_card_shape.deck_name: Anki Deck1`
- `current_card_shape.note_type_name: Basic`
- `current_card_shape.question_length: 5`
- `current_card_shape.answer_length: 13`

The bridge did not return card question text.

The bridge did not return card answer text.

## Privacy flags

The bridge returned:

- `browser_memory_only: true`
- `card_text_returned_by_bridge: false`
- `backend_calls_allowed: false`
- `model_calls_allowed: false`
- `anki_write_allowed: false`
- `mydecks_writeback_allowed: false`

## Safety

No backend deploy, DB write, Anki write, Google Drive write, file upload, card import, media copy, model call, worker activation, scheduler activation, service restart, nginx mutation, or cloudflared mutation was performed.

No Anki card question text or answer text was saved to repo docs.

No Anki card text was sent to backend or model paths.
