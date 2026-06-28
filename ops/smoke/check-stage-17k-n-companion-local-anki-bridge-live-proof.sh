#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-n-companion-local-anki-bridge-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-N — Companion Local Anki Bridge Live Proof' "${DOC}"
grep -Fq '9cd94cd' "${DOC}"
grep -Fq 'controller-stage-17k-n-companion-local-anki-bridge-source-2026-06-28' "${DOC}"
grep -Fq 'stage17kn-companion-local-anki-bridge-source-20260628' "${DOC}"

grep -Fq 'bridge_ready: true' "${DOC}"
grep -Fq 'anki_adapter_present: true' "${DOC}"
grep -Fq 'source_type: anki_browser_local' "${DOC}"
grep -Fq 'status: active' "${DOC}"
grep -Fq 'active: true' "${DOC}"
grep -Fq 'selected_deck_name: Anki Deck1' "${DOC}"
grep -Fq 'card_count_in_memory: 2' "${DOC}"

grep -Fq 'current_card_shape.present: true' "${DOC}"
grep -Fq 'current_card_shape.has_question: true' "${DOC}"
grep -Fq 'current_card_shape.has_answer: true' "${DOC}"
grep -Fq 'current_card_shape.note_type_name: Basic' "${DOC}"
grep -Fq 'current_card_shape.question_length: 5' "${DOC}"
grep -Fq 'current_card_shape.answer_length: 13' "${DOC}"

grep -Fq 'The bridge did not return card question text' "${DOC}"
grep -Fq 'The bridge did not return card answer text' "${DOC}"
grep -Fq 'card_text_returned_by_bridge: false' "${DOC}"
grep -Fq 'backend_calls_allowed: false' "${DOC}"
grep -Fq 'model_calls_allowed: false' "${DOC}"
grep -Fq 'anki_write_allowed: false' "${DOC}"
grep -Fq 'mydecks_writeback_allowed: false' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"
grep -Fq 'No Anki card question text or answer text was saved to repo docs' "${DOC}"

echo "PASS: Stage 17K-N Companion local Anki bridge live proof smoke passed"
