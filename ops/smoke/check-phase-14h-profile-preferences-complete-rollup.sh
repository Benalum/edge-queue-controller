#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-14h-profile-preferences-complete-rollup"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: Profile preferences complete rollup smoke ==="

echo
echo "=== required phase docs and smokes ==="
for f in \
  docs/phase-13x-live-profile-preferences-schema-migration.md \
  docs/phase-13y-live-profile-preferences-read-endpoint.md \
  docs/phase-13z-live-profile-preferences-write-endpoint.md \
  docs/phase-14a-profile-preferences-ui-read.md \
  docs/phase-14b-profile-preferences-runtime-reload-qa.md \
  docs/phase-14c-served-wrapper-profile-preferences-ui-qa.md \
  docs/phase-14d-wrapper-cache-bust-profile-preferences-ui.md \
  docs/phase-14e-public-profile-preferences-wrapper-qa.md \
  docs/phase-14f-profile-preferences-edit-save-ui.md \
  docs/phase-14g-authenticated-profile-preferences-save-qa.md \
  "$DOC"
do
  test -f "$f" || { echo "FAIL: missing doc $f"; fail=1; }
done

for f in \
  ops/smoke/check-phase-13x-live-profile-preferences-schema-migration.sh \
  ops/smoke/check-phase-13y-live-profile-preferences-read-endpoint.sh \
  ops/smoke/check-phase-13z-live-profile-preferences-write-endpoint.sh \
  ops/smoke/check-phase-14a-profile-preferences-ui-read.sh \
  ops/smoke/check-phase-14b-profile-preferences-runtime-reload-qa.sh \
  ops/smoke/check-phase-14c-served-wrapper-profile-preferences-ui-qa.sh \
  ops/smoke/check-phase-14d-wrapper-cache-bust-profile-preferences-ui.sh \
  ops/smoke/check-phase-14e-public-profile-preferences-wrapper-qa.sh \
  ops/smoke/check-phase-14f-profile-preferences-edit-save-ui.sh \
  ops/smoke/check-phase-14g-authenticated-profile-preferences-save-qa.sh \
  "$0"
do
  test -x "$f" || { echo "FAIL: missing executable smoke $f"; fail=1; }
done

echo
echo "=== backend markers ==="
for marker in \
  '@app.get("/api/profile/preferences")' \
  '@app.patch("/api/profile/preferences")' \
  '_profile_preferences_validate_patch' \
  '_profile_preferences_write_response' \
  'app_user_preferences'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing backend marker $marker"; fail=1; }
done

echo
echo "=== frontend markers ==="
for marker in \
  'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' \
  'PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1' \
  'renderProfilePreferencesForm' \
  'collectProfilePreferencesFormPatch' \
  'saveProfilePreferencesFromProfilePage' \
  'bindProfilePreferencesControls' \
  'method: "PATCH"' \
  'api("/profile/preferences"' \
  'data-phase14f-profile-preferences-form' \
  'data-profile-preferences-save'
do
  grep -q "$marker" frontend/wrapper-ui/app.js || { echo "FAIL: missing frontend marker $marker"; fail=1; }
done

grep -q 'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' frontend/wrapper-ui/styles.css || fail=1
grep -q 'PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1' frontend/wrapper-ui/styles.css || fail=1
grep -q '/app.js?v=20260614214f' frontend/wrapper-ui/index.html || fail=1
grep -q './styles.css?v=20260614214f' frontend/wrapper-ui/index.html || fail=1
grep -q '/study/styles.css?v=20260612000409' frontend/wrapper-ui/index.html || fail=1

echo
echo "=== editable UI block safety ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()
start = text.index("// PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1")
end = text.index("function renderLoggedInProfilePage()", start)
block = text[start:end]

required = [
    'method: "PATCH"',
    'api("/profile/preferences"',
    "saveProfilePreferencesFromProfilePage",
    "collectProfilePreferencesFormPatch",
    "bindProfilePreferencesControls",
]
for item in required:
    assert item in block, item

forbidden = [
    "navigator.mediaDevices",
    "getUserMedia",
    "SpeechRecognition",
    "speechSynthesis",
    "speechSynthesis.speak",
    "MediaRecorder",
    "/api/jobs",
    "/api/chat/queued",
    "/api/study/session/command",
    "google_calendar_authorize",
    "apple_calendar_authorize",
    "calendar/events",
    "ollama",
]
bad = [item for item in forbidden if item in block]
assert not bad, bad

print("PASS: editable preferences UI only PATCHes profile preferences")
PY

echo
echo "=== doc markers ==="
for marker in \
  'Phase 14H Profile Preferences Complete Rollup' \
  'Phase 13X' \
  'Phase 13Y' \
  'Phase 13Z' \
  'Phase 14A' \
  'Phase 14G' \
  'PATCH /api/profile/preferences' \
  'GET /api/profile/preferences' \
  'Missing bearer token' \
  'api() helper' \
  'Bearer token' \
  'does not' \
  'microphone capture' \
  'speech output' \
  'Google Calendar' \
  'Apple Calendar' \
  'enqueue jobs' \
  'dispatch workers' \
  'stored preferences only'
do
  grep -qi "$marker" "$DOC" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
