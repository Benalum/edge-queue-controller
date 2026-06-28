#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
PROFILE="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/pages/profile.html"
PANEL="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "${INDEX}"
test -f "${PROFILE}"
test -f "${PANEL}"

grep -Fq "stage17j-r2-profile-cleanup-20260628" "${INDEX}"
grep -Fq "<h1>Your profile</h1>" "${PROFILE}"
grep -Fq "Account information for {{email}}." "${PROFILE}"
grep -Fq "Anki file picker" "${PANEL}"
grep -Fq "APC_STAGE_17J_ANKI_FILE_PICKER_BROWSER_LOCAL" "${PANEL}"
grep -Fq 'event.target.closest("#" + PANEL_ID)' "${PANEL}"
grep -Fq '<details class="apc-anki-manifest-details apc-anki-file-picker-details">' "${PANEL}"

for forbidden in \
  "Private profile" \
  "Password reset is now connected through Resend SMTP." \
  "data-private-open-recover" \
  "Future profile preferences will live here." \
  "Stage 17J ·"; do
  if grep -R -Fq "${forbidden}" "${PROFILE}" "${PANEL}"; then
    echo "FAIL: forbidden visible Profile text remains: ${forbidden}" >&2
    exit 1
  fi
done

if grep -Fq '<details class="apc-anki-manifest-details apc-anki-file-picker-details" open>' "${PANEL}"; then
  echo "FAIL: Anki file picker details should not force open" >&2
  exit 1
fi

if grep -Fq "fetch(" "${PANEL}"; then
  echo "FAIL: Anki file picker must stay browser-local/no fetch" >&2
  exit 1
fi

echo "PASS: Stage 17J-R2 Profile cleanup smoke passed"
