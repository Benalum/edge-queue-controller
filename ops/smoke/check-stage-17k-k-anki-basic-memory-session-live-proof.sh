#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-k-anki-basic-memory-session-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-K — Anki Basic Memory Session Live Proof' "${DOC}"
grep -Fq '2c822f9' "${DOC}"
grep -Fq 'aa8831c' "${DOC}"
grep -Fq 'stage17kk-anki-basic-memory-session-20260628' "${DOC}"
grep -Fq 'apiVersion: stage17kk-anki-basic-memory-session-20260628' "${DOC}"
grep -Fq 'panel: true' "${DOC}"
grep -Fq 'hasMemoryCopy: true' "${DOC}"
grep -Fq 'hasNoBackendCopy: true' "${DOC}"
grep -Fq 'snapshot.status: active' "${DOC}"
grep -Fq 'selection_source_type: anki_browser_local' "${DOC}"
grep -Fq 'selected_deck_name: Anki Deck1' "${DOC}"
grep -Fq 'currentCardShape.hasQuestion: true' "${DOC}"
grep -Fq 'currentCardShape.hasAnswer: true' "${DOC}"
grep -Fq 'currentCardShape.noteTypeName: Basic' "${DOC}"
grep -Fq '/vendor/sqljs/sql-wasm.js' "${DOC}"
grep -Fq '/vendor/sqljs/sql-wasm.wasm' "${DOC}"
grep -Fq 'No CDN resource was used' "${DOC}"
grep -Fq 'card_text_localstorage_allowed: false' "${DOC}"
grep -Fq 'backend_calls_allowed: false' "${DOC}"
grep -Fq 'anki_write_allowed: false' "${DOC}"
grep -Fq 'mydecks_writeback_allowed: false' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"
grep -Fq 'No Anki card text was saved to repo docs' "${DOC}"
grep -Fq 'No backend API call is allowed' "${DOC}"

echo "PASS: Stage 17K-K Anki Basic memory session live proof smoke passed"
