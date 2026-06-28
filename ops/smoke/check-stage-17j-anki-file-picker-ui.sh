#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "${INDEX}"
test -f "${PANEL}"

grep -Fq "stage17j-anki-file-picker-20260628" "${INDEX}"
grep -Fq "Stage 17J · Anki File Picker" "${PANEL}"
grep -Fq "APC_STAGE_17J_ANKI_FILE_PICKER_BROWSER_LOCAL" "${PANEL}"
grep -Fq "Find and choose your Anki file" "${PANEL}"
grep -Fq "Windows desktop" "${PANEL}"
grep -Fq "macOS desktop" "${PANEL}"
grep -Fq "Linux desktop" "${PANEL}"
grep -Fq "Linux Flatpak" "${PANEL}"
grep -Fq "Android / AnkiDroid" "${PANEL}"
grep -Fq "iPhone / iPad AnkiMobile" "${PANEL}"
grep -Fq "collection.anki2" "${PANEL}"
grep -Fq "collection.apkg" "${PANEL}"
grep -Fq "collection.colpkg" "${PANEL}"
grep -Fq "type=\"file\"" "${PANEL}"
grep -Fq "sample_sha256" "${PANEL}"
grep -Fq "Stage 17J reads only the first 1 MiB" "${PANEL}"

if grep -Fq "fetch(" "${PANEL}"; then
  echo "FAIL: Stage 17J file picker must not upload/fetch Anki files" >&2
  exit 1
fi

if grep -Fq "indexedDB" "${PANEL}"; then
  echo "FAIL: Stage 17J should not store full files in IndexedDB" >&2
  exit 1
fi

echo "PASS: Stage 17J Anki file picker UI smoke passed"
