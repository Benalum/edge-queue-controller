#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
DOC="${REPO_ROOT}/docs/stage-17k-s-companion-local-anki-session-mount.md"

test -f "${INDEX}"
test -f "${BRIDGE}"
test -f "${DOC}"

grep -Fq 'stage17ks-companion-local-anki-session-mount-20260628' "${INDEX}"
grep -Fq 'stage17ks-companion-local-anki-session-mount-20260628' "${BRIDGE}"
grep -Fq 'function ankiSessionMountCommand()' "${BRIDGE}"
grep -Fq 'mount_anki_session_adapter' "${BRIDGE}"
grep -Fq 'ankiSessionMountCommand: ankiSessionMountCommand' "${BRIDGE}"
grep -Fq 'Mount local Anki session controls' "${BRIDGE}"
grep -Fq 'apc-companion-local-anki-session-mount-output' "${BRIDGE}"
grep -Fq 'card_text_returned_by_mount_command: false' "${BRIDGE}"
grep -Fq 'backend_calls_allowed: false' "${BRIDGE}"
grep -Fq 'model_calls_allowed: false' "${BRIDGE}"
grep -Fq 'anki_write_allowed: false' "${BRIDGE}"
grep -Fq 'mydecks_writeback_allowed: false' "${BRIDGE}"
grep -Fq 'bindAnkiSessionMountAction();' "${BRIDGE}"

grep -Fq 'Companion Local Anki Session Mount' "${DOC}"
grep -Fq 'APC_ANKI_READONLY_SESSION.renderPanel()' "${DOC}"
grep -Fq 'does not return Anki question text' "${DOC}"
grep -Fq 'does not return Anki answer text' "${DOC}"
grep -Fq 'does not patch `companion.js` MyDecks command handlers' "${DOC}"
grep -Fq 'does not merge Anki cards into `APC_STUDY_STORE`' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${BRIDGE}"; then
  echo "FAIL: forbidden network/API reference found in Anki session mount" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*question|save.*media|save.*note" "${BRIDGE}"; then
  echo "FAIL: possible persistence reference found in Anki session mount" >&2
  exit 1
fi

if grep -RInE "question:\s*card\.question|answer:\s*card\.answer|card\.question\s*,|card\.answer\s*," "${BRIDGE}"; then
  echo "FAIL: mount command appears to return card text" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${BRIDGE}"
fi

echo "PASS: Stage 17K-S Companion local Anki session mount smoke passed"
