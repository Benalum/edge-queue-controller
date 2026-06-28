#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-r-companion-active-anki-session-handoff-plan.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-R — Companion Active Anki Session Handoff Plan' "${DOC}"
grep -Fq '4709542' "${DOC}"
grep -Fq 'stage17kq-companion-local-anki-current-card-shape-command-20260628' "${DOC}"

grep -Fq 'window.APC_ANKI_READONLY_SESSION' "${DOC}"
grep -Fq 'window.APC_COMPANION_LOCAL_ANKI_BRIDGE' "${DOC}"
grep -Fq 'source_type: anki_browser_local' "${DOC}"
grep -Fq 'browser_local_only: true' "${DOC}"
grep -Fq 'can_write_anki: false' "${DOC}"
grep -Fq 'can_upload_anki_content: false' "${DOC}"

grep -Fq 'The existing `companion.js` MyDecks path is not safe for Anki cards' "${DOC}"
grep -Fq 'Do not merge Anki cards into `APC_STUDY_STORE`' "${DOC}"
grep -Fq 'Do not route Anki cards through MyDecks command handlers' "${DOC}"
grep -Fq 'Do not store Anki question text or answer text' "${DOC}"

grep -Fq 'question text' "${DOC}"
grep -Fq 'answer text' "${DOC}"
grep -Fq 'Forbidden:' "${DOC}"
grep -Fq 'backend calls' "${DOC}"
grep -Fq 'model calls' "${DOC}"
grep -Fq 'Anki writes' "${DOC}"
grep -Fq 'MyDecks writeback for Anki cards' "${DOC}"

grep -Fq 'Stage 17K-S should add a local-only Companion Anki session mount' "${DOC}"
grep -Fq 'not patch `companion.js` MyDecks study commands yet' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"
grep -Fq 'docs/smoke-only stage' "${DOC}"

echo "PASS: Stage 17K-R Companion active Anki session handoff plan smoke passed"
