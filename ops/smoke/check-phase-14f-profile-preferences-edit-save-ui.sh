#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-14f-profile-preferences-edit-save-ui"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: editable Profile preferences UI smoke ==="

echo
echo "=== required files ==="
test -f "$DOC" || fail=1
test -f frontend/wrapper-ui/index.html || fail=1
test -f frontend/wrapper-ui/app.js || fail=1
test -f frontend/wrapper-ui/styles.css || fail=1

echo
echo "=== Phase 14F source markers ==="
for marker in \
  'PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1' \
  'profilePreferencesSaving' \
  'profilePreferencesSaveMessage' \
  'renderProfilePreferencesForm' \
  'collectProfilePreferencesFormPatch' \
  'saveProfilePreferencesFromProfilePage' \
  'bindProfilePreferencesControls' \
  'data-phase14f-profile-preferences-form' \
  'data-profile-preferences-save' \
  'data-profile-preferences-refresh' \
  'method: "PATCH"' \
  'api("/profile/preferences"' \
  'Save preferences'
do
  grep -q "$marker" frontend/wrapper-ui/app.js || { echo "FAIL: missing app.js marker $marker"; fail=1; }
done

grep -q 'PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1' frontend/wrapper-ui/styles.css || fail=1
grep -q '/app.js?v=20260614214f' frontend/wrapper-ui/index.html || fail=1
grep -q './styles.css?v=20260614214f' frontend/wrapper-ui/index.html || fail=1

echo
echo "=== Study preview stylesheet remains separate ==="
grep -q '/study/styles.css?v=20260612000409' frontend/wrapper-ui/index.html || fail=1

echo
echo "=== Phase 14F UI write block safety ==="
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
    "data-phase14f-profile-preferences-form",
    "data-profile-preferences-save",
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
echo "=== backend endpoint markers ==="
grep -q '@app.get("/api/profile/preferences")' edge_controller.py || fail=1
grep -q '@app.patch("/api/profile/preferences")' edge_controller.py || fail=1
grep -q '_profile_preferences_validate_patch' edge_controller.py || fail=1
grep -q '_profile_preferences_write_response' edge_controller.py || fail=1

echo
echo "=== doc markers ==="
for marker in \
  'Phase 14F Profile Preferences Edit Save UI' \
  'PATCH /api/profile/preferences' \
  'changed fields' \
  'does not' \
  'microphone capture' \
  'speech output' \
  'Google Calendar' \
  'Apple Calendar' \
  'enqueue jobs' \
  'dispatch workers' \
  'store preferences only'
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
