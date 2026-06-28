#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-j-anki-readonly-session-skeleton-source.md"

test -f "${INDEX}"
test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq "stage17kj-anki-readonly-session-skeleton-20260628" "${INDEX}"
grep -Fq "stage17kj-anki-readonly-session-skeleton-20260628" "${SCRIPT}"
grep -Fq "APC_ANKI_READONLY_SESSION" "${SCRIPT}"
grep -Fq "apc.study.sourceSelection.v1" "${SCRIPT}"
grep -Fq "anki_browser_local" "${SCRIPT}"
grep -Fq "card_text_localstorage_allowed: false" "${SCRIPT}"
grep -Fq "backend_calls_allowed: false" "${SCRIPT}"
grep -Fq "anki_write_allowed: false" "${SCRIPT}"
grep -Fq "mydecks_writeback_allowed: false" "${SCRIPT}"
grep -Fq "card_count_in_memory: 0" "${SCRIPT}"
grep -Fq "Anki read-only session" "${SCRIPT}"
grep -Fq "does not extract card text yet" "${SCRIPT}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: network/API reference found in Anki readonly session skeleton" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem\([^)]*(card|front|back|answer|flds|note|media)" "${SCRIPT}"; then
  echo "FAIL: possible Anki card content localStorage write found" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-J Anki read-only session skeleton source smoke passed"
