#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-k-r2-anki-file-memory-handoff-repair.md"

test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq 'stage17kk-anki-basic-memory-session-20260628' "${SCRIPT}"
grep -Fq 'var selectedAnkiFile = null;' "${SCRIPT}"
grep -Fq 'selectedAnkiFile = file;' "${SCRIPT}"
grep -Fq 'selectedAnkiFile = null;' "${SCRIPT}"
grep -Fq 'var file = selectedAnkiFile ||' "${SCRIPT}"
grep -Fq 'extractBasicCardsIntoMemory(file)' "${SCRIPT}"
grep -Fq 'card_text_localstorage_allowed: false' "${SCRIPT}"
grep -Fq 'backend_calls_allowed: false' "${SCRIPT}"
grep -Fq 'anki_write_allowed: false' "${SCRIPT}"

grep -Fq 'not saved to localStorage' "${DOC}"
grep -Fq 'cleared after extraction starts' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: forbidden network/API reference found after R2 repair" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*front|save.*back|save.*media|save.*note" "${SCRIPT}"; then
  echo "FAIL: possible localStorage/card persistence reference found after R2 repair" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-K-R2 Anki file memory handoff repair smoke passed"
