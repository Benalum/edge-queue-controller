#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13z-live-profile-preferences-write-endpoint"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: live profile preferences write endpoint smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== source markers ==="
for marker in \
  '@app.patch("/api/profile/preferences")' \
  'api_profile_preferences_write' \
  '_profile_preferences_write_response' \
  '_profile_preferences_validate_patch' \
  '_PROFILE_PREFERENCE_ENUM_FIELDS' \
  '_PROFILE_PREFERENCE_FORBIDDEN_WRITE_FIELDS' \
  'phase_13z_live_profile_preferences_write_endpoint' \
  'live_profile_preferences_write_endpoint' \
  'wrote_auth_fields' \
  'wrote_credit_fields' \
  'stored_provider_tokens' \
  'stored_calendar_events' \
  'triggered_model_call' \
  'enqueued_job' \
  'dispatched_worker'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing source marker $marker"; fail=1; }
done

echo
echo "=== route counts ==="
read_count="$(grep -c '@app.get("/api/profile/preferences")' edge_controller.py || true)"
write_count="$(grep -c '@app.patch("/api/profile/preferences")' edge_controller.py || true)"
echo "read_route_count=${read_count}"
echo "write_route_count=${write_count}"
test "$read_count" = "1" || fail=1
test "$write_count" = "1" || fail=1

echo
echo "=== write helper behavior: create then update only one preference row ==="
python3 - <<'PY' || fail=1
import sqlite3
from pathlib import Path

text = Path("edge_controller.py").read_text()
common_start = text.index("_PROFILE_PREFERENCE_FIELDS = [")
common_end = text.index('@app.get("/api/profile/preferences")', common_start)
write_start = text.index("_PROFILE_PREFERENCE_ENUM_FIELDS = {", common_end)
write_end = text.index('@app.patch("/api/profile/preferences")', write_start)
helper_source = text[common_start:common_end] + "\n" + text[write_start:write_end]

ns = {
    "sqlite3": sqlite3,
    "DB_PATH": Path("edge_queue.sqlite3"),
    "HTTPException": RuntimeError,
    "_auth_now_iso": lambda: "2026-06-14T00:00:00+00:00",
}
exec(helper_source, ns)

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
user_id = conn.execute("SELECT id FROM app_users ORDER BY id LIMIT 1").fetchone()["id"]
users_before = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_before = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
conn.execute("DELETE FROM app_user_preferences WHERE user_id = ?", (user_id,))
conn.commit()
prefs_clean = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
conn.close()

create_response = ns["_profile_preferences_write_response"](
    int(user_id),
    {
        "preferred_language": "en",
        "study_language": "es",
        "learning_style": "visual",
        "voice_enabled": True,
        "calendar_provider_preference": "google_calendar",
    },
)

assert create_response["ok"] is True
assert create_response["source"] == "phase_13z_live_profile_preferences_write_endpoint"
assert create_response["mode"] == "live_profile_preferences_write_endpoint"
assert create_response["created"] is True
assert create_response["updated"] is False
assert create_response["preferences"]["study_language"] == "es"
assert create_response["preferences"]["learning_style"] == "visual"
assert create_response["preferences"]["voice_enabled"] is True
assert create_response["preferences"]["calendar_provider_preference"] == "google_calendar"
assert create_response["meta"]["wrote_database"] is True
assert create_response["meta"]["wrote_auth_fields"] is False
assert create_response["meta"]["wrote_credit_fields"] is False
assert create_response["meta"]["stored_provider_tokens"] is False
assert create_response["meta"]["stored_calendar_events"] is False
assert create_response["meta"]["triggered_model_call"] is False
assert create_response["meta"]["enqueued_job"] is False
assert create_response["meta"]["dispatched_worker"] is False

update_response = ns["_profile_preferences_write_response"](
    int(user_id),
    {
        "learning_style": "balanced",
        "voice_enabled": False,
        "calendar_provider_preference": "apple_calendar",
    },
)

assert update_response["ok"] is True
assert update_response["created"] is False
assert update_response["updated"] is True
assert update_response["preferences"]["study_language"] == "es"
assert update_response["preferences"]["learning_style"] == "balanced"
assert update_response["preferences"]["voice_enabled"] is False
assert update_response["preferences"]["calendar_provider_preference"] == "apple_calendar"

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
users_after = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_after = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
row_count = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences WHERE user_id = ?", (user_id,)).fetchone()["c"]
conn.close()

assert users_after == users_before == 47
assert prefs_after == prefs_clean + 1
assert row_count == 1

print(f"PASS: write helper upserted exactly one preference row; user_id={user_id}; prefs_before_clean={prefs_clean}; prefs_after={prefs_after}")
PY

echo
echo "=== validation rejects unknown/forbidden/bad values ==="
python3 - <<'PY' || fail=1
from pathlib import Path
import sqlite3

text = Path("edge_controller.py").read_text()
common_start = text.index("_PROFILE_PREFERENCE_FIELDS = [")
common_end = text.index('@app.get("/api/profile/preferences")', common_start)
write_start = text.index("_PROFILE_PREFERENCE_ENUM_FIELDS = {", common_end)
write_end = text.index('@app.patch("/api/profile/preferences")', write_start)
helper_source = text[common_start:common_end] + "\n" + text[write_start:write_end]

class FakeHTTPException(Exception):
    def __init__(self, status_code=None, detail=None):
        self.status_code = status_code
        self.detail = detail
        super().__init__(f"{status_code}: {detail}")

ns = {
    "sqlite3": sqlite3,
    "DB_PATH": Path("edge_queue.sqlite3"),
    "HTTPException": FakeHTTPException,
    "_auth_now_iso": lambda: "2026-06-14T00:00:00+00:00",
}
exec(helper_source, ns)

validate = ns["_profile_preferences_validate_patch"]

for payload, expected_status in [
    ({"unknown_field": "x"}, 400),
    ({"role": "admin"}, 403),
    ({"learning_style": "bad"}, 422),
    ({"voice_enabled": "yes"}, 422),
    ({}, 400),
]:
    try:
        validate(payload)
    except FakeHTTPException as exc:
        assert exc.status_code == expected_status, (payload, exc.status_code, expected_status)
    else:
        raise AssertionError(f"Expected rejection for {payload}")

print("PASS: validation rejects unknown, forbidden, enum, boolean, and empty payloads")
PY

echo
echo "=== write endpoint block must not contain forbidden runtime markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("_PROFILE_PREFERENCE_ENUM_FIELDS = {")
end = text.index('@app.patch("/api/profile/preferences")', start)
block = text[start:end]

forbidden = [
    "UPDATE app_users",
    "requests.post(",
    "httpx.post(",
    "ollama.generate",
    "enqueue_job(",
    "/api/generate",
    "/api/chat",
    "navigator.mediaDevices",
    "speechSynthesis",
    "SpeechRecognition",
    "getUserMedia",
]
bad = [item for item in forbidden if item in block]
assert not bad, bad
print("PASS: write endpoint block has no forbidden runtime markers")
PY

echo
echo "=== no extra profile preference routes/UI wired ==="
if grep -nE '@app\.(post|put)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.patch\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py; then
  echo "FAIL: Phase 13Z should only add PATCH /api/profile/preferences plus existing GET"
  fail=1
else
  echo "PASS: no profile preference extra routes were added"
fi

frontend_live_markers="$(
  grep -R --exclude='*.bak*' --exclude-dir='__pycache__' -nE '/api/profile/preferences|preferred_language|study_language|learning_style|voice_enabled|calendar_provider_preference' \
    frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css 2>/dev/null \
    || true
)"
if [ -n "$frontend_live_markers" ]; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE:-0}" = "1" ]; then
    echo "$frontend_live_markers"
    python3 - <<'PYCHECK14A'
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

style = Path("frontend/wrapper-ui/styles.css").read_text()
assert "PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1" in style
assert "PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1" in text
assert "PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1" in style
assert 'method: "PATCH"' in text
assert "saveProfilePreferencesFromProfilePage" in text
assert ".profile-preferences-card" in style
assert ".profile-preference-list" in style
assert ".profile-preference-row" in style

print("PASS: Phase 14A read-only Profile preference UI block is explicitly allowed")
PYCHECK14A
  else
    echo "$frontend_live_markers"
    echo "FAIL: frontend preference API markers wired without EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE=1 or EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE=1"
    exit 1
  fi
else
  echo "PASS: no frontend preference API markers were wired"
fi
echo
echo "=== doc markers ==="
for marker in \
  'Phase 13Z Live Profile Preferences Write Endpoint' \
  'PATCH /api/profile/preferences' \
  'app_user_preferences' \
  'reject unknown fields' \
  'reject forbidden fields' \
  'validate enum fields' \
  'validate boolean fields' \
  'upsert one row per user' \
  'google_calendar' \
  'apple_calendar'
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
