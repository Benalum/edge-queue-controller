#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13r-disabled-profile-preferences-schema-design"
fail=0

echo "=== ${PHASE}: disabled profile preferences schema design smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous preference/voice contract smokes ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13q-disabled-profile-study-preferences-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13q-disabled-profile-study-preferences-contract.sh || fail=1
fi
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13p-disabled-voice-settings-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13p-disabled-voice-settings-contract.sh || fail=1
fi

echo
echo "=== static Phase 13R markers ==="
for marker in \
  '_stage5p13r_disabled_profile_preferences_schema_design' \
  'phase_13r_disabled_profile_preferences_schema_design_helper' \
  'disabled_profile_preferences_schema_design_only' \
  'app_user_preferences' \
  'app_users' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'study_explanation_depth' \
  'study_answer_strictness' \
  'study_session_default_mode' \
  'companion_behavior' \
  'companion_tone' \
  'companion_memory_scope' \
  'voice_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'google_calendar' \
  'apple_calendar' \
  'custom_local_calendar_database_allowed' \
  'calendar_event_storage_allowed_in_controller' \
  'requires_schema_migration_plan' \
  'requires_schema_migration_smoke' \
  'requires_unknown_field_rejection_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'no_table_creation' \
  'no_schema_migration' \
  'no_custom_calendar_database'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing marker $marker"; fail=1; }
done

echo
echo "=== helper count ==="
count="$(grep -c '^def _stage5p13r_disabled_profile_preferences_schema_design(' edge_controller.py || true)"
echo "helper_marker_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13r_disabled_profile_preferences_schema_design(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13r_disabled_profile_preferences_schema_design"]
contract = helper(
    "user-1",
    {
        "preferred_language": "en",
        "study_language": "es",
        "learning_style": "visual",
        "calendar_provider_preference": "google_calendar",
    },
)

assert contract["source"] == "phase_13r_disabled_profile_preferences_schema_design_helper"
assert contract["mode"] == "disabled_profile_preferences_schema_design_only"
assert contract["read_only"] is True
assert contract["schema_design_only"] is True
assert contract["runtime_action_available"] is False
assert contract["route_wired"] is False
assert contract["frontend_wired"] is False
assert contract["database_wired"] is False
assert contract["schema_migration_allowed"] is False
assert contract["database_write_allowed"] is False
assert contract["profile_write_allowed"] is False
assert contract["frontend_mutation_allowed"] is False
assert contract["model_call_allowed"] is False
assert contract["job_enqueue_allowed"] is False
assert contract["worker_dispatch_allowed"] is False
assert contract["storage_write_allowed"] is False
assert contract["file_upload_allowed"] is False
assert contract["calendar_write_allowed"] is False
assert contract["tool_call_allowed"] is False

schema = contract["schema_contract"]
assert schema["future_table_name"] == "app_user_preferences"
assert schema["future_owner_table"] == "app_users"
assert schema["future_primary_key"] == "user_id"
assert schema["profile_is_source_of_truth"] is True
assert schema["backend_api_is_authority"] is True
assert schema["frontend_reads_from_backend_only"] is True
assert schema["separate_preferences_table_recommended"] is True
assert schema["avoid_expanding_app_users_for_every_preference"] is True
assert schema["current_table_creation_enabled"] is False
assert schema["current_table_migration_enabled"] is False
assert schema["current_column_migration_enabled"] is False
assert schema["current_route_change_enabled"] is False
assert schema["current_frontend_change_enabled"] is False

defaults = contract["default_value_contract"]
assert defaults["preferred_language"] == "en"
assert defaults["study_language"] == "es"
assert defaults["learning_style"] == "visual"
assert defaults["voice_enabled"] is False
assert defaults["listen_enabled"] is False
assert defaults["speak_enabled"] is False
assert defaults["auto_listen_enabled"] is False
assert defaults["auto_speak_enabled"] is False
assert defaults["calendar_provider_preference"] == "google_calendar"

validation = contract["validation_contract"]
assert validation["allowed_learning_styles"] == ["balanced", "visual", "step_by_step", "concise", "detailed"]
assert validation["allowed_calendar_provider_preferences"] == ["none", "google_calendar", "apple_calendar"]
assert validation["custom_local_calendar_database_allowed"] is False
assert validation["calendar_event_storage_allowed_in_controller"] is False
assert validation["typed_input_must_remain_available"] is True
assert validation["number_word_equivalence_must_remain_available"] is True

endpoints = contract["future_endpoint_contract"]
assert endpoints["read_endpoint"] == "/api/profile/preferences"
assert endpoints["write_endpoint"] == "/api/profile/preferences"
assert endpoints["study_endpoint"] == "/api/profile/study-preferences"
assert endpoints["companion_endpoint"] == "/api/profile/companion-preferences"
assert endpoints["voice_endpoint"] == "/api/profile/voice-settings"
assert endpoints["current_routes_enabled"] is False
assert endpoints["future_writes_require_authenticated_user"] is True
assert endpoints["future_writes_require_field_allowlist"] is True
assert endpoints["future_writes_must_not_accept_unknown_fields"] is True

gates = contract["activation_gates"]
assert gates["requires_schema_migration_plan"] is True
assert gates["requires_schema_migration_smoke"] is True
assert gates["requires_profile_preference_read_endpoint"] is True
assert gates["requires_profile_preference_write_endpoint"] is True
assert gates["requires_authenticated_user_boundary_smoke"] is True
assert gates["requires_field_allowlist_smoke"] is True
assert gates["requires_unknown_field_rejection_smoke"] is True
assert gates["requires_no_calendar_local_storage_smoke"] is True
assert gates["requires_voice_defaults_regression_smoke"] is True
assert gates["requires_typed_input_regression_smoke"] is True

safety = contract["safety"]
assert safety["no_table_creation"] is True
assert safety["no_schema_migration"] is True
assert safety["no_profile_write"] is True
assert safety["no_database_write"] is True
assert safety["no_frontend_mutation"] is True
assert safety["no_model_invocation"] is True
assert safety["no_queue_write"] is True
assert safety["no_worker_dispatch"] is True
assert safety["no_calendar_write"] is True
assert safety["no_custom_calendar_database"] is True
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13R helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13r_disabled_profile_preferences_schema_design_helper' \
  'disabled_profile_preferences_schema_design_only' \
  '_stage5p13r_disabled_profile_preferences_schema_design' \
  'app_user_preferences' \
  'app_users' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'calendar_provider_preference' \
  'google_calendar' \
  'apple_calendar' \
  'custom local calendar database' \
  'controller-owned calendar event storage' \
  '/api/profile/preferences' \
  '/api/profile/study-preferences' \
  '/api/profile/companion-preferences' \
  '/api/profile/voice-settings' \
  'future writes require authenticated user' \
  'future writes require field allowlist' \
  'future writes must reject unknown fields' \
  'requires_schema_migration_plan' \
  'requires_schema_migration_smoke' \
  'requires_unknown_field_rejection_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'no table creation' \
  'no schema migration' \
  'no database write' \
  'no custom calendar database' \
  'no Ollama direct call'
do
  grep -q "$marker" "docs/${PHASE}.md" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no runtime/schema/frontend activation markers in helper ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13r_disabled_profile_preferences_schema_design")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
helper = text[start:end]
forbidden = [
    "requests.post(",
    "httpx.post(",
    "ollama.generate",
    "enqueue_job(",
    "INSERT INTO",
    "UPDATE app_users",
    "UPDATE study_",
    "ALTER TABLE",
    "CREATE TABLE",
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
print("PASS: Phase 13R helper contains no runtime/schema/frontend activation markers")
PY

echo
echo "=== verify frontend files unchanged ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13R should not modify frontend files"
  fail=1
else
  echo "PASS: frontend files unchanged"
fi

echo
echo "=== verify no live preference schema/routes/writes were added ==="
if grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|CREATE TABLE.*app_user_preferences|CREATE TABLE.*preferences|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|FROM app_user_preferences|JOIN app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py; then
  if [ "${EDGE_ALLOW_APP_USER_PREFERENCES_SCHEMA_LIVE:-0}" = "1" ]; then
    if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_READ_ROUTE_LIVE:-0}" = "1" ]; then
      route_or_write_markers="$(
        grep -nE '@app\.(post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|@app\.get\("/api/profile/(study-preferences|companion-preferences|voice-settings)"|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py || true
      )"
    else
      route_or_write_markers="$(
        grep -nE '@app\.(get|post|put|patch)\("/api/profile/(preferences|study-preferences|companion-preferences|voice-settings)"|ALTER TABLE.*app_user_preferences|ALTER TABLE.*preferences|INSERT INTO.*app_user_preferences|UPDATE.*app_user_preferences|DELETE FROM.*app_user_preferences|FROM app_user_preferences|JOIN app_user_preferences|UPDATE app_users.*preferred_language|UPDATE app_users.*study_language|UPDATE app_users.*learning_style' edge_controller.py || true
      )"
    fi

    if [ -n "$route_or_write_markers" ]; then
      echo "$route_or_write_markers"
      echo "FAIL: live route/query/write markers are not allowed by this phase"
      fail=1
    else
      echo "PASS: app_user_preferences schema/read route are live and explicitly allowed by env flags"
    fi
  else
    echo "FAIL: live app_user_preferences schema/query markers should not exist before Phase 13X"
    fail=1
  fi
else
  echo "PASS: no live profile preference schema/query/write markers were found"
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
