#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-14c-served-wrapper-profile-preferences-ui-qa"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: served wrapper Profile preferences UI QA smoke ==="

echo
echo "=== required files ==="
test -f "$DOC" || fail=1
test -f frontend/wrapper-ui/app.js || fail=1
test -f frontend/wrapper-ui/styles.css || fail=1

echo
echo "=== source markers ==="
grep -q 'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' frontend/wrapper-ui/app.js || fail=1
grep -q 'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' frontend/wrapper-ui/styles.css || fail=1
grep -q 'api("/profile/preferences", { method: "GET" })' frontend/wrapper-ui/app.js || fail=1
grep -q '@app.get("/api/profile/preferences")' edge_controller.py || fail=1
grep -q '@app.patch("/api/profile/preferences")' edge_controller.py || fail=1

echo
echo "=== UI block remains read-only ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()
start = text.index("// PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1")
end = text.index("function renderLoggedInProfilePage()", start)
block = text[start:end]

required = [
    'api("/profile/preferences", { method: "GET" })',
    "renderProfilePreferencesCard",
    "renderProfilePreferenceRows",
    "loadProfilePreferencesForProfilePage",
    "if (profilePreferencesError && !force) return null",
]
for item in required:
    assert item in block, item

forbidden = [
    'method: "PATCH"',
    "PATCH /api/profile/preferences",
    "profilePreferencesSave",
    "saveProfilePreferences",
    "data-profile-preferences-save",
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
]
bad = [item for item in forbidden if item in block]
assert not bad, bad

print("PASS: Profile preferences UI remains read-only")
PY

echo
echo "=== doc markers ==="
for marker in \
  'Phase 14C Served Wrapper Profile Preferences UI QA' \
  'Port `7070`' \
  'Port `8787`' \
  '/api/profile/preferences' \
  'must not return `404`' \
  'does not' \
  'microphone capture' \
  'speech output' \
  'Google Calendar' \
  'Apple Calendar' \
  'enqueue jobs' \
  'dispatch workers'
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
