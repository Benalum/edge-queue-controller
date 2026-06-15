#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13y-live-profile-preferences-read-endpoint"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: live profile preferences read endpoint smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== source markers ==="
for marker in \
  '@app.get("/api/profile/preferences")' \
  'api_profile_preferences_read' \
  '_profile_preferences_read_response' \
  '_profile_preferences_safe_defaults' \
  '_profile_preferences_merge_row' \
  '_PROFILE_PREFERENCE_FIELDS' \
  'phase_13y_live_profile_preferences_read_endpoint' \
  'live_profile_preferences_read_endpoint' \
  'created_on_read' \
  'wrote_database' \
  'safe_defaults_returned_when_missing_row' \
  'calendar_provider_preference_only' \
  'custom_local_calendar_database_allowed' \
  'controller_calendar_event_storage_allowed'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing source marker $marker"; fail=1; }
done

echo
echo "=== route count ==="
route_count="$(grep -c '@app.get("/api/profile/preferences")' edge_controller.py || true)"
echo "route_count=${route_count}"
test "$route_count" = "1" || fail=1

echo
echo "=== read helper behavior: no row creation on read ==="
python3 - <<'PY' || fail=1
import sqlite3
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("_PROFILE_PREFERENCE_FIELDS = [")
end = text.index('@app.get("/api/profile/preferences")', start)

ns = {
    "sqlite3": sqlite3,
    "DB_PATH": Path("edge_queue.sqlite3"),
    "HTTPException": RuntimeError,
}
exec(text[start:end], ns)

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
user_id = conn.execute("SELECT id FROM app_users ORDER BY id LIMIT 1").fetchone()["id"]
users_before = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_before = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
conn.close()

response = ns["_profile_preferences_read_response"](int(user_id))

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
users_after = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_after = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
conn.close()

assert users_after == users_before == 47
assert prefs_after == prefs_before == 0

assert response["ok"] is True
assert response["source"] == "phase_13y_live_profile_preferences_read_endpoint"
assert response["mode"] == "live_profile_preferences_read_endpoint"
assert response["user_id"] == int(user_id)
assert response["meta"]["row_exists"] is False
assert response["meta"]["created_on_read"] is False
assert response["meta"]["wrote_database"] is False
assert response["meta"]["safe_defaults_returned_when_missing_row"] is True
assert response["meta"]["source_tables"] == ["app_users", "app_user_preferences"]
assert response["meta"]["profile_is_source_of_truth"] is True
assert response["meta"]["backend_api_is_authority"] is True
assert response["meta"]["frontend_reads_from_backend_only"] is True
assert response["meta"]["calendar_provider_preference_only"] is True
assert response["meta"]["custom_local_calendar_database_allowed"] is False
assert response["meta"]["controller_calendar_event_storage_allowed"] is False

prefs = response["preferences"]
assert prefs["preferred_language"] == "en"
assert prefs["study_language"] == "en"
assert prefs["learning_style"] == "balanced"
assert prefs["study_explanation_depth"] == "normal"
assert prefs["study_answer_strictness"] == "balanced"
assert prefs["study_session_default_mode"] == "standard_review"
assert prefs["companion_behavior"] == "supportive_tutor"
assert prefs["companion_tone"] == "calm_clear"
assert prefs["companion_memory_scope"] == "session_and_profile_approved"
assert prefs["voice_enabled"] is False
assert prefs["listen_enabled"] is False
assert prefs["speak_enabled"] is False
assert prefs["auto_listen_enabled"] is False
assert prefs["auto_speak_enabled"] is False
assert prefs["timezone"] == "profile_default"
assert prefs["locale"] == "en-US"
assert prefs["calendar_provider_preference"] == "none"
assert prefs["notification_preference"] == "none"
assert prefs["accessibility_large_text"] is False
assert prefs["accessibility_reduce_motion"] is False

print(f"PASS: read helper returned defaults without creating row; user_id={user_id}")
PY

echo
echo "=== read endpoint must not contain write/runtime markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("_PROFILE_PREFERENCE_FIELDS = [")
end = text.index('@app.post("/system/account/bootstrap-admin")', start)
block = text[start:end]

forbidden = [
    "INSERT INTO app_user_preferences",
    "UPDATE app_user_preferences",
    "DELETE FROM app_user_preferences",
    "ALTER TABLE app_user_preferences",
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
print("PASS: read endpoint block has no write/runtime markers")
PY

echo
echo "=== database state remains unchanged ==="
python3 - <<'PY' || fail=1
import sqlite3

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
users = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
print(f"app_users_count={users}")
print(f"app_user_preferences_count={prefs}")
assert users == 47
assert prefs == 0
conn.close()
PY

echo
echo "=== no write routes/UI wired ==="
if grep -nE '@app\.(post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py; then
  echo "FAIL: Phase 13Y should only add GET /api/profile/preferences"
  fail=1
else
  echo "PASS: no profile preference write/sub-routes were added"
fi

frontend_live_markers="$(
  grep -R -nE '/api/profile/preferences|preferred_language|study_language|learning_style|voice_enabled|calendar_provider_preference' \
    frontend/study-ui frontend/wrapper-ui public static 2>/dev/null \
    || true
)"
if [ -n "$frontend_live_markers" ]; then
  echo "$frontend_live_markers"
  echo "FAIL: Phase 13Y should not wire frontend preference API markers"
  fail=1
else
  echo "PASS: no frontend preference API markers were wired"
fi

echo
echo "=== doc markers ==="
for marker in \
  'Phase 13Y Live Profile Preferences Read Endpoint' \
  'GET /api/profile/preferences' \
  'app_user_preferences' \
  'returns safe defaults' \
  'create a missing' \
  'preferred_language: en' \
  'learning_style: balanced' \
  'calendar_provider_preference: none' \
  'google_calendar' \
  'apple_calendar' \
  'typed input must remain available'
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
