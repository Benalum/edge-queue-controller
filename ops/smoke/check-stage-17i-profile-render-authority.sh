#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PUBLIC="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/publicpages/publicpages.js"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "${INDEX}"
test -f "${PUBLIC}"
test -f "${PANEL}"

grep -Fq "return !hasLoginToken()" "${PUBLIC}"
grep -Fq "Signed-in users are owned by privatepages" "${PUBLIC}"
grep -Fq "Stage 17I · Anki Manifest" "${PANEL}"
grep -Fq "subtree: false" "${PANEL}"
grep -Fq "apc-private-page-rendered" "${PANEL}"
grep -Fq "stage17i-public-private-route-20260628" "${INDEX}"
grep -Fq "stage17i-profile-mount-loop-20260628" "${INDEX}"

if grep -Fq "publicpages owns public routes for now" "${PUBLIC}"; then
  echo "FAIL: publicpages still claims logged-in private-capable routes" >&2
  exit 1
fi

if grep -Fq "subtree: true" "${PANEL}"; then
  echo "FAIL: Anki profile observer should not watch subtree changes" >&2
  exit 1
fi

echo "PASS: Stage 17I Profile render authority smoke passed"
