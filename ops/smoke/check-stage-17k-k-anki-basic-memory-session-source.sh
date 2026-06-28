#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-k-anki-basic-memory-session-source.md"

test -f "${INDEX}"
test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq "stage17kk-anki-basic-memory-session-20260628" "${INDEX}"
grep -Fq "stage17kk-anki-basic-memory-session-20260628" "${SCRIPT}"
grep -Fq "APC_ANKI_READONLY_SESSION" "${SCRIPT}"
grep -Fq "/vendor/sqljs/sql-wasm.js" "${SCRIPT}"
grep -Fq "/vendor/sqljs/sql-wasm.wasm" "${SCRIPT}"
grep -Fq "extractBasicCardsIntoMemory" "${SCRIPT}"
grep -Fq "FROM cards c JOIN notes n" "${SCRIPT}"
grep -Fq "String.fromCharCode(31)" "${SCRIPT}"
grep -Fq "Front" "${DOC}"
grep -Fq "Back" "${DOC}"
grep -Fq "card_text_localstorage_allowed: false" "${SCRIPT}"
grep -Fq "backend_calls_allowed: false" "${SCRIPT}"
grep -Fq "anki_write_allowed: false" "${SCRIPT}"
grep -Fq "mydecks_writeback_allowed: false" "${SCRIPT}"
grep -Fq "stopSession" "${SCRIPT}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: forbidden network/API reference found in Anki Basic memory session" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*front|save.*back|save.*media|save.*note" "${SCRIPT}"; then
  echo "FAIL: possible localStorage/card persistence reference found" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-K Anki Basic memory session source smoke passed"
