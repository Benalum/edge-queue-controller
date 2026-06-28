#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
SQLJS_DIR="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs"
DOC="${REPO_ROOT}/docs/stage-17k-f-browser-local-anki-deck-ui-source.md"

test -f "${PANEL}"
test -f "${SQLJS_DIR}/sql-wasm.js"
test -f "${SQLJS_DIR}/sql-wasm.wasm"
test -f "${SQLJS_DIR}/SHA256SUMS"
test -f "${DOC}"

grep -Fq "stage17kf-browser-local-deck-ui-20260628" "${PANEL}"
grep -Fq "/vendor/sqljs/sql-wasm.js" "${PANEL}"
grep -Fq "/vendor/sqljs/sql-wasm.wasm" "${PANEL}"
grep -Fq "new SQL.Database" "${PANEL}"
grep -Fq "extractLocalAnkiSummary" "${PANEL}"
grep -Fq "SELECT id, name FROM decks" "${PANEL}"
grep -Fq "SELECT id, name FROM notetypes" "${PANEL}"
grep -Fq "SELECT ntid, ord, name FROM fields" "${PANEL}"
grep -Fq "SELECT ntid, ord, name FROM templates" "${PANEL}"
grep -Fq "anki_browser_local" "${PANEL}"
grep -Fq "deck_names_sent_to_server: false" "${PANEL}"
grep -Fq "card_text_sent_to_server: false" "${PANEL}"
grep -Fq "media_sent_to_server: false" "${PANEL}"
grep -Fq "Sample SHA-256" "${PANEL}"
grep -Fq "hasProof ? ' open'" "${PANEL}"

grep -Fq "Stage 17K-F — Browser-local Anki Deck UI Source Patch" "${DOC}"
grep -Fq "The Anki file remains local to the browser" "${DOC}"
grep -Fq "No backend deploy, DB write, Anki write" "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${PANEL}"; then
  echo "FAIL: network/API reference found in Anki browser-local panel" >&2
  exit 1
fi

if grep -RInE "Paste/update discovery manifest|No Anki profiles are loaded yet|Cards / notes|Profile Anki discovery manifest" \
  "${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages" \
  "${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"; then
  echo "FAIL: old manual manifest UI text found" >&2
  exit 1
fi

(
  cd "${SQLJS_DIR}"
  sha256sum -c SHA256SUMS
)

if command -v node >/dev/null 2>&1; then
  node --check "${PANEL}"
fi

echo "PASS: Stage 17K-F browser-local Anki deck UI source smoke passed"
