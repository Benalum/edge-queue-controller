#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
DOC="${REPO_ROOT}/docs/stage-17k-s-r2-companion-local-anki-session-mount-output-repair.md"

test -f "${INDEX}"
test -f "${BRIDGE}"
test -f "${DOC}"

grep -Fq 'stage17ks-r2-companion-local-anki-session-mount-output-repair-20260628' "${INDEX}"
grep -Fq 'stage17ks-r2-companion-local-anki-session-mount-output-repair-20260628' "${BRIDGE}"
grep -Fq 'function ensureMountOutput(panel)' "${BRIDGE}"
grep -Fq 'ensureMountOutput(document.getElementById(PANEL_ID));' "${BRIDGE}"
grep -Fq 'apc-companion-local-anki-session-mount-output' "${BRIDGE}"
grep -Fq 'Local Anki session controls can be mounted here' "${BRIDGE}"
grep -Fq 'mount_anki_session_adapter' "${BRIDGE}"
grep -Fq 'card_text_returned_by_mount_command: false' "${BRIDGE}"
grep -Fq 'backend_calls_allowed: false' "${BRIDGE}"
grep -Fq 'model_calls_allowed: false' "${BRIDGE}"
grep -Fq 'anki_write_allowed: false' "${BRIDGE}"
grep -Fq 'mydecks_writeback_allowed: false' "${BRIDGE}"

grep -Fq 'Companion Local Anki Session Mount Output Repair' "${DOC}"
grep -Fq 'panelHasMountOutput: false' "${DOC}"
grep -Fq 'does not return Anki question text' "${DOC}"
grep -Fq 'does not return Anki answer text' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${BRIDGE}"; then
  echo "FAIL: forbidden network/API reference found in mount output repair" >&2
  exit 1
fi

if grep -RInE "localStorage\.setItem|writeJson|save.*card|save.*answer|save.*question|save.*media|save.*note" "${BRIDGE}"; then
  echo "FAIL: possible persistence reference found in mount output repair" >&2
  exit 1
fi

if grep -RInE "question:\s*card\.question|answer:\s*card\.answer|card\.question\s*,|card\.answer\s*," "${BRIDGE}"; then
  echo "FAIL: mount repair appears to return card text" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${BRIDGE}"
fi

echo "PASS: Stage 17K-S-R2 Companion local Anki session mount output repair smoke passed"
