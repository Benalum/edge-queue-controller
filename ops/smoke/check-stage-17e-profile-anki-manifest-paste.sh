#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="${REPO_ROOT}/docs/stage-17e-profile-anki-manifest-paste.md"

python3 -m py_compile "${REPO_ROOT}/ops/anki/anki_readonly_discovery.py" "${REPO_ROOT}/ops/anki/anki_discovery_manifest.py"

test -f "${PANEL}"
test -f "${INDEX}"
test -f "${DOC}"

grep -Fq '/privatepages/anki-manifest-panel.js?v=stage17e-profile-anki-manifest-20260628' "${INDEX}"
grep -Fq 'Stage 17E · Anki Manifest' "${PANEL}"
grep -Fq 'currentRoute() === "/profile"' "${PANEL}"
grep -Fq 'APC_PROFILE_ANKI_MANIFEST_PANEL' "${PANEL}"
grep -Fq 'Save manifest to profile' "${PANEL}"
grep -Fq 'No Anki writes' "${PANEL}"
grep -Fq 'no backend save' "${PANEL}"
grep -Fq 'Stage 17E — Profile Anki Manifest Paste Source' "${DOC}"

if grep -Eq 'fetch\(|/api/study|/api/profile|method: "POST"|method: "PATCH"|collection\.anki2.*write|AnkiConnect' "${PANEL}"; then
  echo "FAIL: Stage 17E panel must stay browser-local/read-only" >&2
  exit 1
fi

echo "PASS: Stage 17E Profile Anki manifest paste smoke passed"
