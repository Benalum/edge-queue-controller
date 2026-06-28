#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-h-study-source-selector-ui-preflight.md"

test -f "${DOC}"

grep -Fq "Stage 17K-H — Study Source Selector UI Preflight" "${DOC}"
grep -Fq "Study with Anki" "${DOC}"
grep -Fq "Study with MyDecks" "${DOC}"
grep -Fq "Anki remains browser-local and read-only" "${DOC}"
grep -Fq "MyDecks remains the APC-native deck source" "${DOC}"
grep -Fq "frontend-only Study source selector UI" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

test -f "${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
test -d "${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages"
test -f "${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

echo "PASS: Stage 17K-H Study source selector UI preflight smoke passed"
