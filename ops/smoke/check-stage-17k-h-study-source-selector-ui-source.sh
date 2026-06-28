#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
SCRIPT="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js"
DOC="${REPO_ROOT}/docs/stage-17k-h-study-source-selector-ui-source.md"

test -f "${INDEX}"
test -f "${SCRIPT}"
test -f "${DOC}"

grep -Fq "stage17kh-study-source-selector-ui-20260628" "${INDEX}"
grep -Fq "stage17kh-study-source-selector-ui-20260628" "${SCRIPT}"
grep -Fq "stage17kf-browser-local-deck-ui-20260628" "${INDEX}"
grep -Fq "Study with Anki" "${SCRIPT}"
grep -Fq "Study with MyDecks" "${SCRIPT}"
grep -Fq "apc.study.sourceSelection.v1" "${SCRIPT}"
grep -Fq "apc.profile.anki.localDeckSummary.v1" "${SCRIPT}"
grep -Fq "anki_browser_local" "${SCRIPT}"
grep -Fq "mydecks_apc_native" "${SCRIPT}"
grep -Fq "can_write_anki: false" "${SCRIPT}"
grep -Fq "can_upload_anki_content: false" "${SCRIPT}"
grep -Fq "No backend deploy, DB write, Anki write" "${DOC}"

if grep -RInE "fetch\(|XMLHttpRequest|sendBeacon|/api/|https?://|unpkg|jsdelivr|cdnjs" "${SCRIPT}"; then
  echo "FAIL: network/API reference found in Study source selector" >&2
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "${SCRIPT}"
fi

echo "PASS: Stage 17K-H Study source selector UI source smoke passed"
