#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "${INDEX}"
test -f "${PANEL}"

grep -Fq "stage17j-r4c-file-proof-visible-20260628" "${INDEX}"
grep -Fq "Anki file picker" "${PANEL}"
grep -Fq "Choose your Anki file" "${PANEL}"
grep -Fq "hasProof ? ' open' : ''" "${PANEL}"
grep -Fq "File status" "${PANEL}"
grep -Fq "Sample SHA-256" "${PANEL}"
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
  "renderProfiles" \
  "renderDeckRows" \
  "validateManifest" \
  "TEXTAREA_ID" \
  "apc-anki-summary-list"; do
  if grep -Fq "${forbidden}" "${PANEL}"; then
    echo "FAIL: old manual manifest code remains: ${forbidden}" >&2
    exit 1
  fi
done

if grep -Fq "fetch(" "${PANEL}"; then
  echo "FAIL: Anki file picker must stay browser-local/no fetch" >&2
  exit 1
fi

echo "PASS: Stage 17J-R4C file proof visible smoke passed"
