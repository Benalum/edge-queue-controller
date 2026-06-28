#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
DOC="${REPO_ROOT}/docs/stage-17k-q-companion-local-anki-current-card-shape-command.md"

test -f "${INDEX}"
test -f "${BRIDGE}"
test -f "${DOC}"

grep -Fq 'stage17kq-companion-local-anki-current-card-shape-command-20260628' "${INDEX}"
grep -Fq 'stage17kq-companion-local-anki-current-card-shape-command-20260628' "${BRIDGE}"
grep -Fq 'function currentCardShapeCommand()' "${BRIDGE}"
grep -Fq 'current_anki_card_shape' "${BRIDGE}"
grep -Fq 'currentCardShapeCommand: currentCardShapeCommand' "${BRIDGE}"
grep -Fq 'Describe current local Anki card shape' "${BRIDGE}"
grep -Fq 'apc-companion-local-anki-command-output' "${BRIDGE}"
grep -Fq 'card_text_returned_by_command: false' "${BRIDGE}"
grep -Fq 'card_text_returned_by_bridge: false' "${BRIDGE}"
grep -Fq 'backend_calls_allowed: false' "${BRIDGE}"
grep -Fq 'model_calls_allowed: false' "${BRIDGE}"
grep -Fq 'anki_write_allowed: false' "${BRIDGE}"
grep -Fq 'mydecks_writeback_allowed: false' "${BRIDGE}"

grep -Fq 'Companion Local Anki Current Card Shape Command' "${DOC}"
grep -Fq 'does not return Anki question text' "${DOC}"
grep -Fq 'does not return Anki answer text' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${BRIDGE}"; then
  echo "FAIL: forbidden network/API reference found in current-card-shape command" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*question|save.*media|save.*note" "${BRIDGE}"; then
  echo "FAIL: possible persistence reference found in current-card-shape command" >&2
  exit 1
fi

if grep -RInE "question:\s*card\.question|answer:\s*card\.answer|card\.question\s*,|card\.answer\s*," "${BRIDGE}"; then
  echo "FAIL: command appears to return card text" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${BRIDGE}"
fi

echo "PASS: Stage 17K-Q Companion local Anki current card shape command smoke passed"
