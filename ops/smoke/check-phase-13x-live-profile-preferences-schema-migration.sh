#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13x-live-profile-preferences-schema-migration"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: live profile preferences schema migration smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== source markers ==="
for marker in \
  '_account_init_profile_preferences_table' \
  'CREATE TABLE IF NOT EXISTS app_user_preferences' \
  'idx_app_user_preferences_updated_at' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'companion_behavior' \
  'voice_enabled' \
  'listen_enabled' \
  'speak_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'google_calendar' \
  'apple_calendar' \
  'FOREIGN KEY(user_id) REFERENCES app_users(id)' \
  '_account_init_profile_preferences_table(conn)'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing source marker $marker"; fail=1; }
done

echo
echo "=== run source migration helper twice and verify database ==="
python3 - <<'PY' || fail=1
import sqlite3
from pathlib import Path

db_path = Path("edge_queue.sqlite3")
text = Path("edge_controller.py").read_text()

start = text.index("def _account_init_profile_preferences_table(conn):")
end = text.index("\ndef _account_init_tables():", start)
ns = {}
exec(text[start:end], ns)
migrate = ns["_account_init_profile_preferences_table"]

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
conn.execute("PRAGMA foreign_keys = ON")

tables_before = {
    str(r["name"])
    for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
}
assert "app_users" in tables_before

users_before = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]

migrate(conn)
conn.commit()
migrate(conn)
conn.commit()

tables_after = {
    str(r["name"])
    for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
}
assert "app_user_preferences" in tables_after

users_after = conn.execute("SELECT COUNT(*) AS c FROM app_users").fetchone()["c"]
prefs_after = conn.execute("SELECT COUNT(*) AS c FROM app_user_preferences").fetchone()["c"]
assert users_after == users_before, (users_before, users_after)
import os
if os.getenv("EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE") == "1":
    assert prefs_after >= 1, prefs_after
else:
    assert prefs_after == 0, prefs_after

columns = {
    str(r["name"]): dict(r)
    for r in conn.execute("PRAGMA table_info(app_user_preferences)").fetchall()
}

required = {
    "user_id",
    "preferred_language",
    "study_language",
    "learning_style",
    "study_explanation_depth",
    "study_answer_strictness",
    "study_session_default_mode",
    "companion_behavior",
    "companion_tone",
    "companion_memory_scope",
    "voice_enabled",
    "listen_enabled",
    "speak_enabled",
    "auto_listen_enabled",
    "auto_speak_enabled",
    "timezone",
    "locale",
    "calendar_provider_preference",
    "notification_preference",
    "accessibility_large_text",
    "accessibility_reduce_motion",
    "created_at",
    "updated_at",
}
missing = sorted(required - set(columns))
assert not missing, missing

assert columns["user_id"]["pk"] == 1
for bool_col in [
    "voice_enabled",
    "listen_enabled",
    "speak_enabled",
    "auto_listen_enabled",
    "auto_speak_enabled",
    "accessibility_large_text",
    "accessibility_reduce_motion",
]:
    assert str(columns[bool_col]["type"]).upper() == "INTEGER"
    assert columns[bool_col]["notnull"] == 1
    assert str(columns[bool_col]["dflt_value"]) == "0"

for forbidden in [
    "password",
    "password_hash",
    "session",
    "token",
    "oauth",
    "api_key",
    "secret",
    "credit",
    "paid",
    "free_credit",
    "calendar_event",
    "event_json",
    "audio",
    "blob",
    "transcript",
    "model_output",
]:
    assert forbidden not in columns, forbidden

foreign_keys = [dict(r) for r in conn.execute("PRAGMA foreign_key_list(app_user_preferences)").fetchall()]
assert any(fk.get("table") == "app_users" and fk.get("from") == "user_id" and fk.get("to") == "id" for fk in foreign_keys), foreign_keys

indexes = {
    str(r["name"])
    for r in conn.execute("PRAGMA index_list(app_user_preferences)").fetchall()
}
assert "idx_app_user_preferences_updated_at" in indexes

conn.close()

print(f"PASS: app_user_preferences migrated; app_users_count={users_after}; app_user_preferences_count={prefs_after}")
PY

echo
echo "=== no live preference routes/UI wired ==="
if grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"' edge_controller.py; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE:-0}" = "1" ]; then
    disallowed_routes="$(
      grep -nE '@app\.(post|put)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.patch\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py || true
    )"
    if [ -n "$disallowed_routes" ]; then
      echo "$disallowed_routes"
      echo "FAIL: Phase 13Z allows only GET/PATCH /api/profile/preferences, not write/sub-routes"
      fail=1
    else
      echo "PASS: GET/PATCH /api/profile/preferences are live and explicitly allowed by route env flags"
    fi
  elif [ "${EDGE_ALLOW_PROFILE_PREFERENCES_READ_ROUTE_LIVE:-0}" = "1" ]; then
    disallowed_routes="$(
      grep -nE '@app\.(post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"' edge_controller.py || true
    )"
    if [ -n "$disallowed_routes" ]; then
      echo "$disallowed_routes"
      echo "FAIL: Phase 13Y allows only GET /api/profile/preferences, not write/sub-routes"
      fail=1
    else
      echo "PASS: GET /api/profile/preferences is live and explicitly allowed by EDGE_ALLOW_PROFILE_PREFERENCES_READ_ROUTE_LIVE=1"
    fi
  else
    echo "FAIL: live profile preference routes should not exist before Phase 13Y"
    fail=1
  fi
else
  echo "PASS: no live profile preference routes were added"
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
  'Phase 13X Live Profile Preferences Schema Migration' \
  '_account_init_profile_preferences_table' \
  'app_user_preferences' \
  'user_id references app_users.id' \
  'app_user_preferences row count remains 0' \
  'google_calendar' \
  'apple_calendar' \
  'Typed input must remain available'
do
  grep -q "$marker" "$DOC" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
