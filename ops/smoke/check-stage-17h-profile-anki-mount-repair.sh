#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PROFILE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html"

test -f "${PANEL}"
test -f "${INDEX}"
test -f "${PROFILE}"

grep -Fq "Stage 17H · Anki Manifest" "${PANEL}"
grep -Fq "MutationObserver" "${PANEL}"
grep -Fq ".private-grid" "${PANEL}"
grep -Fq ".private-card" "${PANEL}"
grep -Fq "stage17h-profile-anki-mount-20260628" "${INDEX}"
grep -Fq "Private profile" "${PROFILE}"
grep -Fq "Future profile preferences will live here." "${PROFILE}"

if grep -Fq "fetch(" "${PANEL}"; then
  echo "FAIL: Anki profile panel must stay browser-local/read-only" >&2
  exit 1
fi

echo "PASS: Stage 17H Profile Anki mount repair smoke passed"
