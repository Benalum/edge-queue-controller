#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-k-r3-preserve-active-anki-memory-session.md"

test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq 'stage17kk-anki-basic-memory-session-20260628' "${SCRIPT}"
grep -Fq 'Anki cards are already loaded in browser memory' "${SCRIPT}"
grep -Fq 'memoryState.status = memoryState.active ? "active" : memoryState.status;' "${SCRIPT}"
grep -Fq 'card_text_localstorage_allowed: false' "${SCRIPT}"
grep -Fq 'backend_calls_allowed: false' "${SCRIPT}"
grep -Fq 'anki_write_allowed: false' "${SCRIPT}"
grep -Fq 'mydecks_writeback_allowed: false' "${SCRIPT}"

grep -Fq 'Preserve Active Anki Memory Session' "${DOC}"
grep -Fq 'active: true' "${DOC}"
grep -Fq 'card_count_in_memory: 2' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: forbidden network/API reference found after R3 repair" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*front|save.*back|save.*media|save.*note" "${SCRIPT}"; then
  echo "FAIL: possible localStorage/card persistence reference found after R3 repair" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-K-R3 preserve active Anki memory session smoke passed"
