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

row = conn.execute(
    """
    SELECT id
    FROM app_users
    WHERE id NOT IN (SELECT user_id FROM app_user_preferences)
    ORDER BY id
    LIMIT 1
    """
).fetchone()

if row is None:
    row = conn.execute("SELECT id FROM app_users ORDER BY id LIMIT 1").fetchone()

user_id = int(row["id"])
users_before = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_before = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
row_exists_before = conn.execute(
    "SELECT COUNT(*) AS c FROM app_user_preferences WHERE user_id = ?",
    (user_id,),
).fetchone()["c"] == 1
conn.close()

response = ns["_profile_preferences_read_response"](user_id)

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
users_after = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_after = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
row_exists_after = conn.execute(
    "SELECT COUNT(*) AS c FROM app_user_preferences WHERE user_id = ?",
    (user_id,),
).fetchone()["c"] == 1
conn.close()

assert users_after == users_before == 47
assert prefs_after == prefs_before
assert row_exists_after == row_exists_before

assert response["ok"] is True
assert response["source"] == "phase_13y_live_profile_preferences_read_endpoint"
assert response["mode"] == "live_profile_preferences_read_endpoint"
assert response["user_id"] == user_id
assert response["meta"]["row_exists"] is row_exists_before
assert response["meta"]["created_on_read"] is False
assert response["meta"]["wrote_database"] is False
assert response["meta"]["safe_defaults_returned_when_missing_row"] is (not row_exists_before)
assert response["meta"]["source_tables"] == ["app_users", "app_user_preferences"]
assert response["meta"]["profile_is_source_of_truth"] is True
assert response["meta"]["backend_api_is_authority"] is True
assert response["meta"]["frontend_reads_from_backend_only"] is True
assert response["meta"]["calendar_provider_preference_only"] is True
assert response["meta"]["custom_local_calendar_database_allowed"] is False
assert response["meta"]["controller_calendar_event_storage_allowed"] is False

prefs = response["preferences"]
assert prefs["preferred_language"]
assert prefs["study_language"]
assert prefs["learning_style"] in {"balanced", "visual", "step_by_step", "concise", "detailed"}
assert isinstance(prefs["voice_enabled"], bool)
assert isinstance(prefs["listen_enabled"], bool)
assert isinstance(prefs["speak_enabled"], bool)
assert prefs["calendar_provider_preference"] in {"none", "google_calendar", "apple_calendar"}

if not row_exists_before:
    assert prefs["preferred_language"] == "en"
    assert prefs["study_language"] == "en"
    assert prefs["learning_style"] == "balanced"
    assert prefs["voice_enabled"] is False
    assert prefs["calendar_provider_preference"] == "none"

print(f"PASS: read helper did not create rows; user_id={user_id}; row_exists={row_exists_before}; prefs_count={prefs_after}")
PY

echo
echo "=== read endpoint block must not contain write/runtime markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("_PROFILE_PREFERENCE_FIELDS = [")
end = text.index('@app.get("/api/profile/preferences")', start)
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
echo "=== database state remains compatible ==="
python3 - <<'PY' || fail=1
import os
import sqlite3

conn = sqlite3.connect("edge_queue.sqlite3")
conn.row_factory = sqlite3.Row
users = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
print(f"app_users_count={users}")
print(f"app_user_preferences_count={prefs}")
assert users == 47
if os.getenv("EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE") == "1":
    assert prefs >= 1
else:
    assert prefs == 0
conn.close()
PY

echo
echo "=== route compatibility ==="
if grep -nE '@app\.(post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE:-0}" = "1" ]; then
    disallowed_routes="$(
      grep -nE '@app\.(post|put)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.patch\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py || true
    )"
    if [ -n "$disallowed_routes" ]; then
      echo "$disallowed_routes"
      echo "FAIL: Phase 13Z allows only GET/PATCH /api/profile/preferences, not extra routes"
      fail=1
    else
      echo "PASS: PATCH /api/profile/preferences is live and explicitly allowed by EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE=1"
    fi
  else
    echo "FAIL: Phase 13Y should only add GET /api/profile/preferences"
    fail=1
  fi
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
