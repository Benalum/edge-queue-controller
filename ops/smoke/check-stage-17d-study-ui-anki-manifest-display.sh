#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
DOC="${REPO_ROOT}/docs/stage-17d-study-ui-anki-manifest-display.md"

test -f "${INDEX}"
test -f "${PANEL}"
test -f "${DOC}"

grep -Fq '/privatepages/anki-manifest-panel.js' "${INDEX}"
grep -Fq 'Stage 17D' "${PANEL}"
grep -Fq 'apc_anki_discovery_manifest' "${PANEL}"
grep -Fq 'writes_performed=false' "${PANEL}"
grep -Fq 'No Anki writes' "${PANEL}"
grep -Fq 'Stage 17D' "${DOC}"

if grep -Eq 'fetch\(|XMLHttpRequest|/api/study|/api/companion|collection\.anki2|collection\.media' "${PANEL}"; then
  echo "FAIL: Stage 17D panel must remain display-only and avoid API/file mutation paths" >&2
  exit 1
fi

echo "PASS: Stage 17D Study UI Anki manifest display smoke passed"
