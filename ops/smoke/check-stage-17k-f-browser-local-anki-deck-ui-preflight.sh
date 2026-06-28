#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
PROFILE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html"
SQLJS_DIR="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/vendor/sqljs"
DOC="${REPO_ROOT}/docs/stage-17k-f-browser-local-anki-deck-ui-preflight.md"

test -f "${PANEL}"
test -f "${PROFILE}"
test -f "${SQLJS_DIR}/sql-wasm.js"
test -f "${SQLJS_DIR}/sql-wasm.wasm"
test -f "${SQLJS_DIR}/SHA256SUMS"
test -f "${DOC}"

grep -Fq "Stage 17K-F — Browser-local Anki Deck UI Preflight" "${DOC}"
grep -Fq "Anki remains browser-local and read-only" "${DOC}"
grep -Fq "Load sql.js from same-origin vendored assets" "${DOC}"
grep -Fq "Extract deck names from the newer decks table" "${DOC}"
grep -Fq "The server must not receive" "${DOC}"
grep -Fq "source type: anki_browser_local" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

grep -Fq "buildFileProof" "${PANEL}"
grep -Fq "readSavedFileProof" "${PANEL}"
grep -Fq "Sample SHA" "${PANEL}"

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

echo "PASS: Stage 17K-F browser-local Anki deck UI preflight smoke passed"
