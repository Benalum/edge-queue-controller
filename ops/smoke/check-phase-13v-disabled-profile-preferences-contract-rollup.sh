#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13v-disabled-profile-preferences-contract-rollup"
fail=0

echo "=== ${PHASE}: disabled profile preferences contract rollup smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== dependency profile stack ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency profile stack (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/run-stack-quiet.sh profile || fail=1
fi

echo
echo "=== static Phase 13V markers ==="
for marker in \
  '_stage5p13v_disabled_profile_preferences_contract_rollup' \
  'phase_13v_disabled_profile_preferences_contract_rollup_helper' \
  'disabled_profile_preferences_contract_rollup_only' \
  'rollup_contract_only' \
  'component_contracts' \
  'profile_preference_stack_readiness' \
  'future_live_activation_order' \
  'endpoint_rollup_contract' \
  'calendar_rollup_contract' \
  'voice_rollup_contract' \
  'privacy_permission_rollup' \
  'phase-13p-disabled-voice-settings-contract' \
  'phase-13q-disabled-profile-study-preferences-contract' \
  'phase-13r-disabled-profile-preferences-schema-design' \
  'phase-13s-disabled-profile-preferences-read-endpoint-contract' \
  'phase-13t-disabled-profile-preferences-write-endpoint-contract' \
  'phase-13u-disabled-profile-preferences-ui-support-contract' \
  'rollup_complete_for_disabled_contracts' \
  'all_components_disabled' \
  'all_components_source_only' \
  'all_components_unwired' \
  'ready_for_future_live_schema_phase' \
  'ready_for_future_live_read_endpoint_phase' \
  'ready_for_future_live_write_endpoint_phase' \
  'ready_for_future_profile_settings_ui_phase' \
  'live_activation_allowed_now' \
  'app_user_preferences' \
  '/api/profile/preferences' \
  'future_read_method' \
  'future_write_method' \
  'future_write_uses_field_allowlist' \
  'future_write_rejects_unknown_fields' \
  'future_write_rejects_forbidden_fields' \
  'future_write_validates_enum_values' \
  'future_write_validates_boolean_values' \
  'allowed_future_calendar_providers' \
  'google_calendar' \
  'apple_calendar' \
  'custom_local_calendar_database_allowed' \
  'controller_calendar_event_storage_allowed' \
  'controller_owned_calendar_event_storage_allowed' \
  'calendar_events_must_not_be_stored_by_controller' \
  'provider_tokens_must_not_be_visible' \
  'voice_defaults_remain_disabled' \
  'auto_listen_default_must_remain_false' \
  'auto_speak_default_must_remain_false' \
  'typed_input_must_remain_available' \
  'requires_schema_migration_smoke' \
  'requires_read_endpoint_smoke' \
  'requires_write_endpoint_smoke' \
  'requires_final_live_rollup_before_enable' \
  'no_route_registration' \
  'no_database_read' \
  'no_database_write' \
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
count="$(grep -c '^def _stage5p13v_disabled_profile_preferences_contract_rollup(' edge_controller.py || true)"
echo "phase13v_definition_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13v_disabled_profile_preferences_contract_rollup(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13v_disabled_profile_preferences_contract_rollup"]
contract = helper("user-1")

assert contract["source"] == "phase_13v_disabled_profile_preferences_contract_rollup_helper"
assert contract["mode"] == "disabled_profile_preferences_contract_rollup_only"
assert contract["read_only"] is True
assert contract["rollup_contract_only"] is True
assert contract["runtime_action_available"] is False
assert contract["route_wired"] is False
assert contract["frontend_wired"] is False
assert contract["profile_settings_ui_wired"] is False
assert contract["database_wired"] is False
assert contract["database_read_allowed_now"] is False
assert contract["database_write_allowed_now"] is False
assert contract["schema_migration_allowed"] is False
assert contract["profile_write_allowed"] is False
assert contract["frontend_mutation_allowed"] is False
assert contract["model_call_allowed"] is False
assert contract["job_enqueue_allowed"] is False
assert contract["worker_dispatch_allowed"] is False
assert contract["storage_write_allowed"] is False
assert contract["file_upload_allowed"] is False
assert contract["calendar_write_allowed"] is False
assert contract["tool_call_allowed"] is False
assert contract["execute_now"] is False
assert contract["would_call"] == "none"

components = contract["component_contracts"]
assert len(components) == 6
helpers = {item["helper"] for item in components}
for required in {
    "_stage5p13p_disabled_voice_settings_contract",
    "_stage5p13q_disabled_profile_study_preferences_contract",
    "_stage5p13r_disabled_profile_preferences_schema_design",
    "_stage5p13s_disabled_profile_preferences_read_endpoint_contract",
    "_stage5p13t_disabled_profile_preferences_write_endpoint_contract",
    "_stage5p13u_disabled_profile_preferences_ui_support_contract",
}:
    assert required in helpers

readiness = contract["profile_preference_stack_readiness"]
assert readiness["rollup_complete_for_disabled_contracts"] is True
assert readiness["profile_preference_schema_design_present"] is True
assert readiness["profile_preference_read_contract_present"] is True
assert readiness["profile_preference_write_contract_present"] is True
assert readiness["profile_preference_ui_support_contract_present"] is True
assert readiness["voice_settings_contract_present"] is True
assert readiness["study_preference_contract_present"] is True
assert readiness["all_components_disabled"] is True
assert readiness["all_components_source_only"] is True
assert readiness["all_components_unwired"] is True
assert readiness["ready_for_future_live_schema_phase"] is True
assert readiness["ready_for_future_live_read_endpoint_phase"] is False
assert readiness["ready_for_future_live_write_endpoint_phase"] is False
assert readiness["ready_for_future_profile_settings_ui_phase"] is False
assert readiness["live_activation_allowed_now"] is False

endpoint = contract["endpoint_rollup_contract"]
assert endpoint["future_read_endpoint"] == "/api/profile/preferences"
assert endpoint["future_read_method"] == "GET"
assert endpoint["future_write_endpoint"] == "/api/profile/preferences"
assert endpoint["future_write_method"] == "PATCH"
assert endpoint["current_read_route_enabled"] is False
assert endpoint["current_write_route_enabled"] is False
assert endpoint["current_profile_settings_ui_enabled"] is False
assert endpoint["future_routes_require_authenticated_user"] is True
assert endpoint["future_routes_use_backend_api_authority"] is True
assert endpoint["future_read_returns_safe_defaults"] is True
assert endpoint["future_read_must_not_write_on_read"] is True
assert endpoint["future_write_uses_field_allowlist"] is True
assert endpoint["future_write_rejects_unknown_fields"] is True
assert endpoint["future_write_rejects_forbidden_fields"] is True
assert endpoint["future_write_validates_enum_values"] is True
assert endpoint["future_write_validates_boolean_values"] is True
assert endpoint["future_routes_must_not_return_secrets"] is True
assert endpoint["future_routes_must_not_change_auth_fields"] is True
assert endpoint["future_routes_must_not_change_credit_fields"] is True
assert endpoint["future_routes_must_not_trigger_model_call"] is True
assert endpoint["future_routes_must_not_enqueue_job"] is True
assert endpoint["future_routes_must_not_dispatch_worker"] is True

calendar = contract["calendar_rollup_contract"]
assert calendar["allowed_future_calendar_providers"] == ["none", "google_calendar", "apple_calendar"]
assert calendar["calendar_provider_preference_only"] is True
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["controller_calendar_event_storage_allowed"] is False
assert calendar["controller_owned_calendar_event_storage_allowed"] is False
assert calendar["calendar_provider_connection_required_before_calendar_reads"] is True
assert calendar["calendar_writes_require_explicit_user_request"] is True
assert calendar["calendar_events_must_not_be_stored_by_controller"] is True
assert calendar["provider_tokens_must_not_be_visible"] is True

voice = contract["voice_rollup_contract"]
assert voice["voice_settings_contract_present"] is True
assert voice["voice_defaults_remain_disabled"] is True
assert voice["listen_default_must_remain_false"] is True
assert voice["speak_default_must_remain_false"] is True
assert voice["auto_listen_default_must_remain_false"] is True
assert voice["auto_speak_default_must_remain_false"] is True
assert voice["browser_microphone_requires_explicit_user_action"] is True
assert voice["browser_speech_output_requires_explicit_user_action"] is True
assert voice["typed_input_must_remain_available"] is True

privacy = contract["privacy_permission_rollup"]
assert privacy["no_profile_write_in_this_phase"] is True
assert privacy["no_background_personalization_changes"] is True
assert privacy["no_sensitive_attribute_inference"] is True
assert privacy["preferences_must_not_expose_secrets"] is True
assert privacy["ui_must_not_expose_auth_fields"] is True
assert privacy["ui_must_not_expose_credit_fields"] is True
assert privacy["ui_must_not_expose_provider_tokens"] is True
assert privacy["routes_must_not_accept_auth_fields"] is True
assert privacy["routes_must_not_accept_credit_fields"] is True
assert privacy["routes_must_not_store_calendar_events"] is True
assert privacy["routes_must_not_store_audio_blobs"] is True
assert privacy["routes_must_not_trigger_model_call"] is True
assert privacy["routes_must_not_enqueue_job"] is True
assert privacy["routes_must_not_dispatch_worker"] is True

gates = contract["activation_gates"]
assert gates["requires_schema_migration_smoke"] is True
assert gates["requires_read_endpoint_smoke"] is True
assert gates["requires_write_endpoint_smoke"] is True
assert gates["requires_authenticated_user_boundary_smoke"] is True
assert gates["requires_safe_defaults_smoke"] is True
assert gates["requires_no_write_on_read_smoke"] is True
assert gates["requires_field_allowlist_smoke"] is True
assert gates["requires_unknown_field_rejection_smoke"] is True
assert gates["requires_forbidden_field_rejection_smoke"] is True
assert gates["requires_enum_validation_smoke"] is True
assert gates["requires_boolean_validation_smoke"] is True
assert gates["requires_no_secret_exposure_smoke"] is True
assert gates["requires_no_auth_field_change_smoke"] is True
assert gates["requires_no_credit_field_change_smoke"] is True
assert gates["requires_profile_settings_ui_smoke"] is True
assert gates["requires_study_ui_preference_read_smoke"] is True
assert gates["requires_companion_ui_preference_read_smoke"] is True
assert gates["requires_voice_defaults_regression_smoke"] is True
assert gates["requires_typed_input_regression_smoke"] is True
assert gates["requires_no_calendar_local_storage_smoke"] is True
assert gates["requires_no_controller_calendar_event_storage_smoke"] is True
assert gates["requires_final_live_rollup_before_enable"] is True

safety = contract["safety"]
assert safety["not_connected_to_live_profile_routes"] is True
assert safety["not_connected_to_live_profile_settings_ui"] is True
assert safety["not_connected_to_live_study_ui"] is True
assert safety["not_connected_to_live_companion_ui"] is True
assert safety["no_route_registration"] is True
assert safety["no_database_read"] is True
assert safety["no_database_write_now"] is True
assert safety["no_table_creation"] is True
assert safety["no_schema_migration"] is True
assert safety["no_profile_write"] is True
assert safety["no_database_write"] is True
assert safety["no_frontend_mutation"] is True
assert safety["no_model_invocation"] is True
assert safety["no_queue_write"] is True
assert safety["no_worker_dispatch"] is True
assert safety["no_storage_write"] is True
assert safety["no_file_upload"] is True
assert safety["no_calendar_write"] is True
assert safety["no_custom_calendar_database"] is True
assert safety["no_controller_calendar_event_storage"] is True
assert safety["no_browser_microphone_access"] is True
assert safety["no_browser_speech_output"] is True
assert safety["no_tool_call"] is True
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13V helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13v_disabled_profile_preferences_contract_rollup_helper' \
  'disabled_profile_preferences_contract_rollup_only' \
  '_stage5p13v_disabled_profile_preferences_contract_rollup' \
  'phase-13p-disabled-voice-settings-contract' \
  'phase-13q-disabled-profile-study-preferences-contract' \
  'phase-13r-disabled-profile-preferences-schema-design' \
  'phase-13s-disabled-profile-preferences-read-endpoint-contract' \
  'phase-13t-disabled-profile-preferences-write-endpoint-contract' \
  'phase-13u-disabled-profile-preferences-ui-support-contract' \
  'rollup_complete_for_disabled_contracts' \
  'all_components_disabled' \
  'all_components_source_only' \
  'all_components_unwired' \
  'ready_for_future_live_schema_phase' \
  'live_activation_allowed_now' \
  'app_user_preferences' \
  '/api/profile/preferences' \
  'GET' \
  'PATCH' \
  'future_write_uses_field_allowlist' \
  'future_write_rejects_unknown_fields' \
  'future_write_rejects_forbidden_fields' \
  'none' \
  'google_calendar' \
  'apple_calendar' \
  'custom_local_calendar_database_allowed' \
  'controller_calendar_event_storage_allowed' \
  'controller_owned_calendar_event_storage_allowed' \
  'voice_defaults_remain_disabled' \
  'typed_input_must_remain_available' \
  'requires_schema_migration_smoke' \
  'requires_read_endpoint_smoke' \
  'requires_write_endpoint_smoke' \
  'requires_final_live_rollup_before_enable' \
  'no_route_registration' \
  'no_database_write' \
  'no_frontend_mutation' \
  'no_model_invocation' \
  'no_queue_write' \
  'no_worker_dispatch' \
  'no_calendar_write' \
  'no_custom_calendar_database' \
  'no_controller_calendar_event_storage' \
  'no_ollama_direct_call' \
  'ops/smoke/run-stack-quiet.sh profile'
do
  grep -q "$marker" "docs/${PHASE}.md" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no runtime/route/schema/frontend/voice activation markers in helper ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13v_disabled_profile_preferences_contract_rollup")
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
print("PASS: Phase 13V helper contains no runtime/route/schema/frontend/voice activation markers")
PY

echo
echo "=== verify frontend/public/static files unchanged ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui public static || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13V should not modify frontend/public/static files"
  fail=1
else
  echo "PASS: frontend/public/static files unchanged"
fi

echo
echo "=== verify no live preference UI/API/schema/writes were added ==="
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

frontend_live_markers="$(
  grep -R -nE '/api/profile/preferences|preferred_language|study_language|learning_style|voice_enabled|calendar_provider_preference' \
    frontend/study-ui frontend/wrapper-ui public static 2>/dev/null \
    || true
)"
if [ -n "$frontend_live_markers" ]; then
  echo "$frontend_live_markers"
  echo "FAIL: disabled Phase 13V should not wire frontend preference API markers"
  fail=1
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
