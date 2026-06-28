#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-k-r4-anki-active-status-repair.md"

test -f "${INDEX}"
test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq 'stage17kk-anki-basic-memory-session-20260628-r4-status-repair' "${INDEX}"
grep -Fq 'stage17kk-anki-basic-memory-session-20260628' "${SCRIPT}"
grep -Fq 'Stage 17K-K-R4 preserved the active local session' "${SCRIPT}"
grep -Fq 'if (!file && memoryState.cards && memoryState.cards.length)' "${SCRIPT}"
grep -Fq 'memoryState.status = memoryState.active ? "active" : memoryState.status;' "${SCRIPT}"
grep -Fq 'return snapshot();' "${SCRIPT}"
grep -Fq 'card_text_localstorage_allowed: false' "${SCRIPT}"
grep -Fq 'backend_calls_allowed: false' "${SCRIPT}"
grep -Fq 'anki_write_allowed: false' "${SCRIPT}"
grep -Fq 'mydecks_writeback_allowed: false' "${SCRIPT}"

grep -Fq 'Anki Active Status Repair' "${DOC}"
grep -Fq 'active: true' "${DOC}"
grep -Fq 'card_count_in_memory: 2' "${DOC}"
grep -Fq 'Static frontend only' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: forbidden network/API reference found after R4 repair" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*front|save.*back|save.*media|save.*note" "${SCRIPT}"; then
  echo "FAIL: possible localStorage/card persistence reference found after R4 repair" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-K-R4 Anki active status repair smoke passed"
