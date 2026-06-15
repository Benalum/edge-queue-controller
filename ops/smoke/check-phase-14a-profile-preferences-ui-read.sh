#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-14a-profile-preferences-ui-read"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: Profile UI read-only preferences smoke ==="

echo
echo "=== required files ==="
test -f frontend/wrapper-ui/app.js || fail=1
test -f frontend/wrapper-ui/styles.css || fail=1
test -f "$DOC" || fail=1

echo
echo "=== app.js markers ==="
for marker in \
  'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' \
  'let profilePreferences = null' \
  'let profilePreferencesLoading = false' \
  'let profilePreferencesError = ""' \
  'function normalizeProfilePreferenceValue' \
  'function renderProfilePreferenceRows' \
  'function renderProfilePreferencesCard' \
  'async function loadProfilePreferencesForProfilePage' \
  'api("/profile/preferences", { method: "GET" })' \
  'if (profilePreferencesError && !force) return null' \
  'renderProfilePreferencesCard()' \
  'data-phase14a-profile-preferences-card' \
  'data-phase14a-profile-preferences-list' \
  'Read-only display' \
  'Saving comes in a later phase' \
  'Typed input remains available'
do
  grep -q "$marker" frontend/wrapper-ui/app.js || { echo "FAIL: missing app.js marker $marker"; fail=1; }
done

echo
echo "=== no write/browser activation markers in Phase 14A block ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()
start = text.index("// PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1")
end = text.index("function renderLoggedInProfilePage()", start)
block = text[start:end]

required = [
    'api("/profile/preferences", { method: "GET" })',
    "renderProfilePreferencesCard",
    "loadProfilePreferencesForProfilePage",
    "if (profilePreferencesError && !force) return null",
]
for item in required:
    assert item in block, item

forbidden = [
    'method: "PATCH"',
    "PATCH /api/profile/preferences",
    "navigator.mediaDevices",
    "getUserMedia",
    "SpeechRecognition",
    "speechSynthesis.speak",
    "/api/jobs",
    "/api/chat/queued",
    "/api/study/session/command",
    "google_calendar_authorize",
    "apple_calendar_authorize",
]
bad = [item for item in forbidden if item in block]
assert not bad, bad

print("PASS: Phase 14A UI block is read-only and does not activate voice/calendar/jobs/models")
PY

echo
echo "=== render branch calls loader after profile render ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("frontend/wrapper-ui/app.js").read_text()
needle = '''if (path === "/profile")'''
start = text.index(needle)
end = text.index('const isCredits = path === "/credits";', start)
block = text[start:end]

assert '$("app").innerHTML = renderLoggedInProfilePage();' in block
assert 'loadProfilePreferencesForProfilePage();' in block
assert 'PATCH' not in block
print("PASS: profile route renders page and starts read-only preference load")
PY

echo
echo "=== styles markers ==="
for marker in \
  'PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1' \
  '.profile-preferences-card' \
  '.profile-preference-list' \
  '.profile-preference-row'
do
  grep -q "$marker" frontend/wrapper-ui/styles.css || { echo "FAIL: missing styles marker $marker"; fail=1; }
done

echo
echo "=== doc markers ==="
for marker in \
  'Phase 14A Profile Preferences UI Read' \
  'GET /api/profile/preferences' \
  'read-only' \
  'must not' \
  'PATCH /api/profile/preferences' \
  'Typed input must remain available' \
  'Google Calendar' \
  'Apple Calendar'
do
  grep -qi "$marker" "$DOC" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no active UI save controls added ==="
if grep -R -nE 'profilePreferencesSave|saveProfilePreferences|data-profile-preferences-save|PATCH /api/profile/preferences|method: "PATCH".*profile/preferences|/api/profile/preferences.*PATCH' \
  frontend/wrapper-ui 2>/dev/null \
  --exclude='*.bak*' \
  --exclude-dir='__pycache__'; then
  echo "FAIL: Phase 14A must not add preference save controls"
  fail=1
else
  echo "PASS: no preference save controls found"
fi

echo
echo "=== backend route still present in code ==="
grep -q '@app.get("/api/profile/preferences")' edge_controller.py || fail=1
grep -q '@app.patch("/api/profile/preferences")' edge_controller.py || fail=1
python3 -m py_compile edge_controller.py || fail=1

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
