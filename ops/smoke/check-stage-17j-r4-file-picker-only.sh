#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "${INDEX}"
test -f "${PANEL}"

grep -Fq "stage17j-r4-file-picker-only-20260628" "${INDEX}"
grep -Fq "Anki file picker" "${PANEL}"
grep -Fq "Choose your Anki file" "${PANEL}"
grep -Fq "<summary>Choose Anki file</summary>" "${PANEL}"
grep -Fq "APC_STAGE_17J_ANKI_FILE_PICKER_BROWSER_LOCAL" "${PANEL}"
grep -Fq "Windows desktop" "${PANEL}"
grep -Fq "Android / AnkiDroid" "${PANEL}"
grep -Fq "iPhone / iPad AnkiMobile" "${PANEL}"
grep -Fq "File status" "${PANEL}"
grep -Fq "sample_sha256" "${PANEL}"

for forbidden in \
  "Profile Anki discovery manifest" \
  "Paste/update discovery manifest" \
  "Generate with ops/anki/anki_readonly_discovery.py" \
  "Paste /tmp/apc-anki-manifest.json here" \
  "Save manifest to profile" \
  "Clear saved manifest" \
  "No Anki profiles are loaded yet." \
  "Cards / notes" \
  "renderProfiles(manifest)" \
  "apc-anki-summary-list"; do
  if grep -Fq "${forbidden}" "${PANEL}"; then
    echo "FAIL: old manual manifest UI remains: ${forbidden}" >&2
    exit 1
  fi
done

if grep -Fq "fetch(" "${PANEL}"; then
  echo "FAIL: Anki file picker must stay browser-local/no fetch" >&2
  exit 1
fi

echo "PASS: Stage 17J-R4 file picker only smoke passed"
