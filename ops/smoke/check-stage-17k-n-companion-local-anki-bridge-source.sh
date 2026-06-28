#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
DOC="${REPO_ROOT}/docs/stage-17k-n-companion-local-anki-bridge-source.md"

test -f "${INDEX}"
test -f "${BRIDGE}"
test -f "${DOC}"

grep -Fq 'stage17kn-companion-local-anki-bridge-source-20260628' "${INDEX}"
grep -Fq 'stage17kn-companion-local-anki-bridge-source-20260628' "${BRIDGE}"
grep -Fq 'APC_COMPANION_LOCAL_ANKI_BRIDGE' "${BRIDGE}"
grep -Fq 'APC_ANKI_READONLY_SESSION' "${BRIDGE}"
grep -Fq 'currentCardShape' "${BRIDGE}"
grep -Fq 'snapshot' "${BRIDGE}"
grep -Fq 'question_length' "${BRIDGE}"
grep -Fq 'answer_length' "${BRIDGE}"
grep -Fq 'card_text_returned_by_bridge: false' "${BRIDGE}"
grep -Fq 'backend_calls_allowed: false' "${BRIDGE}"
grep -Fq 'model_calls_allowed: false' "${BRIDGE}"
grep -Fq 'anki_write_allowed: false' "${BRIDGE}"
grep -Fq 'mydecks_writeback_allowed: false' "${BRIDGE}"

grep -Fq 'Companion Local Anki Bridge Source' "${DOC}"
grep -Fq 'does not return Anki card question text or answer text' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${BRIDGE}"; then
  echo "FAIL: forbidden network/API reference found in Companion local Anki bridge" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*question|save.*media|save.*note" "${BRIDGE}"; then
  echo "FAIL: possible persistence reference found in Companion local Anki bridge" >&2
  exit 1
fi

if grep -RInE "question:\s*card\.question|answer:\s*card\.answer|card\.question\s*,|card\.answer\s*," "${BRIDGE}"; then
  echo "FAIL: bridge appears to return card text" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${BRIDGE}"
fi

echo "PASS: Stage 17K-N Companion local Anki bridge source smoke passed"
