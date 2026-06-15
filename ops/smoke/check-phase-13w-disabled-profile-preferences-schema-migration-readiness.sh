#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13w-disabled-profile-preferences-schema-migration-readiness"
DOC="docs/${PHASE}.md"
fail=0

echo "=== ${PHASE}: disabled schema migration readiness smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== dependency profile stack ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency profile stack (EDGE_SMOKE_SKIP_DEPS=1)"
else
  EDGE_SMOKE_SKIP_DEPS=1 ops/smoke/run-quiet.sh phase-13v ops/smoke/check-phase-13v-disabled-profile-preferences-contract-rollup.sh || fail=1
  ops/smoke/run-stack-quiet.sh profile || fail=1
fi

echo
echo "=== source markers ==="
for marker in \
  '_stage5p13w_profile_preferences_schema_migration_readiness' \
  'phase_13w_profile_preferences_schema_migration_readiness_helper' \
  'disabled_profile_preferences_schema_migration_readiness_only' \
  'schema_migration_readiness_only' \
  'app_user_preferences' \
  'edge_queue.sqlite3' \
  '_account_init_tables' \
  '_account_add_column_if_missing' \
  '_auth_current_user_from_request' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'companion_behavior' \
  'voice_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'google_calendar' \
  'apple_calendar' \
  'future_migration_must_be_idempotent' \
  'future_migration_must_not_create_preference_rows_for_existing_users' \
  'verify_migration_creates_app_user_preferences' \
  'verify_app_users_row_count_unchanged' \
  'verify_no_preference_rows_created_by_migration' \
  'custom_local_calendar_database_allowed' \
  'controller_calendar_event_storage_allowed' \
  'typed_input_must_remain_available' \
  'no_route_registration' \
  'no_database_read' \
  'no_database_write_now' \
  'no_table_creation' \
  'no_schema_migration' \
  'no_profile_write' \
  'no_frontend_mutation' \
  'no_model_invocation' \
  'no_queue_write' \
  'no_worker_dispatch' \
  'no_calendar_write' \
  'no_custom_calendar_database' \
  'no_controller_calendar_event_storage' \
  'no_ollama_direct_call'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing source marker $marker"; fail=1; }
done

echo
echo "=== helper count by definition only ==="
count="$(grep -c '^def _stage5p13w_profile_preferences_schema_migration_readiness(' edge_controller.py || true)"
echo "phase13w_definition_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13w_profile_preferences_schema_migration_readiness(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

contract = ns["_stage5p13w_profile_preferences_schema_migration_readiness"]("user-1")

assert contract["source"] == "phase_13w_profile_preferences_schema_migration_readiness_helper"
assert contract["mode"] == "disabled_profile_preferences_schema_migration_readiness_only"
assert contract["read_only"] is True
assert contract["inspection_only"] is True
assert contract["schema_migration_readiness_only"] is True
assert contract["runtime_action_available"] is False
assert contract["route_wired"] is False
assert contract["frontend_wired"] is False
assert contract["database_wired"] is False
assert contract["database_read_allowed_now"] is False
assert contract["database_write_allowed_now"] is False
assert contract["schema_migration_allowed"] is False
assert contract["profile_write_allowed"] is False
assert contract["model_call_allowed"] is False
assert contract["job_enqueue_allowed"] is False
assert contract["worker_dispatch_allowed"] is False
assert contract["calendar_write_allowed"] is False
assert contract["tool_call_allowed"] is False
assert contract["execute_now"] is False
assert contract["would_call"] == "none"

observed = contract["observed_runtime_readiness"]
assert observed["database_engine"] == "sqlite3"
assert observed["observed_database_file"] == "edge_queue.sqlite3"
assert observed["account_table"] == "app_users"
assert observed["account_init_function"] == "_account_init_tables"
assert observed["auth_user_helper"] == "_auth_current_user_from_request"

schema = contract["future_schema_contract"]
assert schema["table_name"] == "app_user_preferences"
assert schema["owner_table"] == "app_users"
assert schema["primary_key"] == "user_id"
assert schema["one_row_per_user"] is True
assert schema["create_row_on_read"] is False
assert schema["read_endpoint_returns_defaults_without_row"] is True
assert schema["write_endpoint_may_create_or_update_row_later"] is True
assert schema["avoid_expanding_app_users_for_every_preference"] is True
assert schema["must_not_store_auth_fields"] is True
assert schema["must_not_store_credit_fields"] is True
assert schema["must_not_store_provider_tokens"] is True
assert schema["must_not_store_calendar_events"] is True
assert schema["must_not_store_audio_blobs"] is True

columns = set(schema["preference_columns"])
for required in {
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
}:
    assert required in columns

assert schema["enum_columns"]["calendar_provider_preference"] == ["none", "google_calendar", "apple_calendar"]
assert schema["safe_defaults"]["voice_enabled"] is False
assert schema["safe_defaults"]["auto_listen_enabled"] is False
assert schema["safe_defaults"]["auto_speak_enabled"] is False
assert schema["safe_defaults"]["learning_style"] == "balanced"

plan = contract["migration_safety_plan"]
assert plan["current_phase_creates_table"] is False
assert plan["current_phase_alters_tables"] is False
assert plan["current_phase_reads_database"] is False
assert plan["current_phase_writes_database"] is False
assert plan["future_migration_must_be_idempotent"] is True
assert plan["future_migration_must_preserve_existing_app_users"] is True
assert plan["future_migration_must_not_create_preference_rows_for_existing_users"] is True
assert plan["future_migration_must_not_modify_auth_or_credit_columns"] is True
assert plan["future_migration_must_not_register_routes"] is True
assert plan["future_migration_must_not_modify_frontend"] is True

gates = contract["future_schema_smoke_gates"]
assert gates["verify_migration_creates_app_user_preferences"] is True
assert gates["verify_required_columns_exist"] is True
assert gates["verify_migration_idempotent_on_second_run"] is True
assert gates["verify_app_users_row_count_unchanged"] is True
assert gates["verify_no_preference_rows_created_by_migration"] is True
assert gates["verify_health_200_after_migration"] is True
assert gates["verify_profile_contract_stack_after_migration"] is True

calendar = contract["calendar_boundary"]
assert calendar["allowed_provider_preferences"] == ["none", "google_calendar", "apple_calendar"]
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["controller_calendar_event_storage_allowed"] is False
assert calendar["calendar_provider_preference_only"] is True

voice = contract["voice_boundary"]
assert voice["voice_defaults_disabled"] is True
assert voice["auto_listen_default_false"] is True
assert voice["auto_speak_default_false"] is True
assert voice["typed_input_must_remain_available"] is True

safety = contract["safety"]
assert safety["no_route_registration"] is True
assert safety["no_database_read"] is True
assert safety["no_database_write_now"] is True
assert safety["no_table_creation"] is True
assert safety["no_schema_migration"] is True
assert safety["no_profile_write"] is True
assert safety["no_frontend_mutation"] is True
assert safety["no_model_invocation"] is True
assert safety["no_queue_write"] is True
assert safety["no_worker_dispatch"] is True
assert safety["no_calendar_write"] is True
assert safety["no_custom_calendar_database"] is True
assert safety["no_controller_calendar_event_storage"] is True
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13W helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'Phase 13W Disabled Profile Preferences Schema Migration Readiness' \
  '_stage5p13w_profile_preferences_schema_migration_readiness' \
  'phase_13w_profile_preferences_schema_migration_readiness_helper' \
  'disabled_profile_preferences_schema_migration_readiness_only' \
  'schema_migration_readiness_only' \
  'edge_queue.sqlite3' \
  'app_user_preferences' \
  'app_users' \
  'user_id references app_users.id' \
  'create_row_on_read: false' \
  'read_endpoint_returns_defaults_without_row: true' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'companion_behavior' \
  'voice_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'google_calendar' \
  'apple_calendar' \
  'must not store' \
  'future_migration_must_be_idempotent' \
  'verify_migration_creates_app_user_preferences' \
  'verify_app_users_row_count_unchanged' \
  'custom_local_calendar_database_allowed: false' \
  'controller_calendar_event_storage_allowed: false' \
  'typed_input_must_remain_available: true' \
  'no_route_registration' \
  'no_database_read' \
  'no_database_write_now' \
  'no_table_creation' \
  'no_schema_migration' \
  'no_ollama_direct_call'
do
  grep -q "$marker" "$DOC" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== verify helper contains no executable migration/runtime markers ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13w_profile_preferences_schema_migration_readiness")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
helper = text[start:end]

forbidden = [
    "requests.post(",
    "httpx.post(",
    "ollama.generate",
    "enqueue_job(",
    "sqlite3.connect(",
    "conn.execute(",
    "INSERT INTO",
    "UPDATE app_users",
    "UPDATE study_",
    "ALTER TABLE",
    "CREATE TABLE",
    "DELETE FROM",
    "FROM app_user_preferences",
    "JOIN app_user_preferences",
    "@app.",
    "APIRouter",
    "/api/generate",
    "/api/chat",
    "write_text(",
    "open(",
    "navigator.mediaDevices",
    "speechSynthesis",
    "SpeechRecognition",
    "getUserMedia",
]
bad = [item for item in forbidden if item in helper]
assert not bad, bad
print("PASS: Phase 13W helper contains no executable migration/runtime markers")
PY

echo
echo "=== verify no live schema/routes/UI were added ==="
if grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|CREATE TABLE.*app_user_preferences|CREATE TABLE.*preferences|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|FROM app_user_preferences|JOIN app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py; then
  if [ "${EDGE_ALLOW_APP_USER_PREFERENCES_SCHEMA_LIVE:-0}" = "1" ]; then
    if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_WRITE_ROUTE_LIVE:-0}" = "1" ]; then
      disallowed_markers="$(
        grep -nE '@app\.(post|put)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.patch\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|DELETE FROM.*app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py || true
      )"
    elif [ "${EDGE_ALLOW_PROFILE_PREFERENCES_READ_ROUTE_LIVE:-0}" = "1" ]; then
      disallowed_markers="$(
        grep -nE '@app\.(post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py || true
      )"
    else
      disallowed_markers="$(
        grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|FROM app_user_preferences|JOIN app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py || true
      )"
    fi

    if [ -n "$disallowed_markers" ]; then
      echo "$disallowed_markers"
      echo "FAIL: live markers are not allowed by this phase/env"
      fail=1
    else
      echo "PASS: profile preferences schema/read/write route are live and explicitly allowed by env flags"
    fi
  else
    echo "FAIL: live app_user_preferences schema/query markers should not exist before Phase 13X"
    fail=1
  fi
else
  echo "PASS: no live profile preference schema/query/write markers were found"
fi

if grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"' edge_controller.py; then
  echo "FAIL: live profile preference routes should not exist"
  fail=1
else
  echo "PASS: no live profile preference routes were added"
fi

frontend_live_markers="$(
  grep -R --exclude='*.bak*' --exclude-dir='__pycache__' -nE '/api/profile/preferences|preferred_language|study_language|learning_style|voice_enabled|calendar_provider_preference' \
    frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css 2>/dev/null \
    || true
)"
if [ -n "$frontend_live_markers" ]; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ]; then
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
    'method: "PATCH"',
    "PATCH /api/profile/preferences",
    "profilePreferencesSave",
    "saveProfilePreferences",
    "data-profile-preferences-save",
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
assert ".profile-preferences-card" in style
assert ".profile-preference-list" in style
assert ".profile-preference-row" in style

print("PASS: Phase 14A read-only Profile preference UI block is explicitly allowed")
PYCHECK14A
  else
    echo "$frontend_live_markers"
    echo "FAIL: frontend preference API markers wired without EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE=1"
    exit 1
  fi
else
  echo "PASS: no frontend preference API markers were wired"
fi
echo
echo "=== safety: power auto full tick remains quarantined ==="
env_dump="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr ' ' '\n' | grep -E '^EDGE_POWER_AUTO_PAUSED=|^EDGE_POWER_AUTO_TICK_FULL=' || true)"
echo "$env_dump"
echo "$env_dump" | grep -q '^EDGE_POWER_AUTO_PAUSED=0$' || fail=1
echo "$env_dump" | grep -q '^EDGE_POWER_AUTO_TICK_FULL=0$' || fail=1

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
