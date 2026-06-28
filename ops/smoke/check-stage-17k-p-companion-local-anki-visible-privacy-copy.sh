#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
DOC="${REPO_ROOT}/docs/stage-17k-p-companion-local-anki-visible-privacy-copy.md"

test -f "${INDEX}"
test -f "${BRIDGE}"
test -f "${DOC}"

grep -Fq 'stage17kp-companion-local-anki-visible-privacy-copy-20260628' "${INDEX}"
grep -Fq 'stage17kp-companion-local-anki-visible-privacy-copy-20260628' "${BRIDGE}"
grep -Fq 'APC_COMPANION_LOCAL_ANKI_BRIDGE' "${BRIDGE}"
grep -Fq 'This bridge does not return card question text or answer text.' "${BRIDGE}"
grep -Fq 'apc-companion-local-anki-visible-privacy-copy' "${BRIDGE}"
grep -Fq 'card_text_returned_by_bridge: false' "${BRIDGE}"
grep -Fq 'backend_calls_allowed: false' "${BRIDGE}"
grep -Fq 'model_calls_allowed: false' "${BRIDGE}"
grep -Fq 'anki_write_allowed: false' "${BRIDGE}"
grep -Fq 'mydecks_writeback_allowed: false' "${BRIDGE}"

grep -Fq 'Companion Local Anki Visible Privacy Copy' "${DOC}"
grep -Fq 'panelTextHasPrivacyCopy' "${DOC}"
grep -Fq 'does not return Anki question text' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${BRIDGE}"; then
  echo "FAIL: forbidden network/API reference found in visible privacy repair" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*question|save.*media|save.*note" "${BRIDGE}"; then
  echo "FAIL: possible persistence reference found in visible privacy repair" >&2
  exit 1
fi

if grep -RInE "question:\s*card\.question|answer:\s*card\.answer|card\.question\s*,|card\.answer\s*," "${BRIDGE}"; then
  echo "FAIL: bridge appears to return card text" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${BRIDGE}"
fi

echo "PASS: Stage 17K-P Companion local Anki visible privacy copy smoke passed"
