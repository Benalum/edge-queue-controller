#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13t-disabled-profile-preferences-write-endpoint-contract"
fail=0

echo "=== ${PHASE}: disabled profile preferences write endpoint contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous profile/preference contract smokes ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13s-disabled-profile-preferences-read-endpoint-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13s-disabled-profile-preferences-read-endpoint-contract.sh || fail=1
fi
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13r-disabled-profile-preferences-schema-design.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13r-disabled-profile-preferences-schema-design.sh || fail=1
fi
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
echo "=== static Phase 13T markers ==="
for marker in \
  '_stage5p13t_disabled_profile_preferences_write_endpoint_contract' \
  'phase_13t_disabled_profile_preferences_write_endpoint_contract_helper' \
  'disabled_profile_preferences_write_endpoint_contract_only' \
  'write_endpoint_contract_only' \
  'database_write_allowed_now' \
  '/api/profile/preferences' \
  'future_route_requires_authenticated_user' \
  'future_route_uses_field_allowlist' \
  'future_route_rejects_unknown_fields' \
  'future_route_rejects_forbidden_fields' \
  'future_route_validates_enum_values' \
  'future_route_validates_boolean_values' \
  'future_route_must_not_change_auth_fields' \
  'future_route_must_not_change_credit_fields' \
  'accepted_preview' \
  'rejected_preview' \
  'enum_allowlists' \
  'boolean_fields' \
  'forbidden_fields' \
  'field_not_allowed' \
  'enum_value_not_allowed' \
  'boolean_required' \
  'text_required' \
  'app_users' \
  'app_user_preferences' \
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
  'calendar_events_must_not_be_stored_by_controller' \
  'voice_defaults_remain_disabled' \
  'browser_microphone_requires_explicit_user_action' \
  'write_endpoint_must_not_accept_auth_fields' \
  'write_endpoint_must_not_accept_credit_fields' \
  'write_endpoint_must_not_store_calendar_events' \
  'write_endpoint_must_not_store_audio_blobs' \
  'requires_profile_preference_write_route' \
  'requires_field_allowlist_smoke' \
  'requires_unknown_field_rejection_smoke' \
  'requires_forbidden_field_rejection_smoke' \
  'requires_enum_validation_smoke' \
  'requires_boolean_validation_smoke' \
  'requires_no_auth_field_change_smoke' \
  'requires_no_credit_field_change_smoke' \
  'no_route_registration' \
  'no_database_write_now' \
  'no_custom_calendar_database'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing marker $marker"; fail=1; }
done

echo
echo "=== helper count ==="
count="$(grep -c '^def _stage5p13t_disabled_profile_preferences_write_endpoint_contract(' edge_controller.py || true)"
echo "helper_marker_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13t_disabled_profile_preferences_write_endpoint_contract(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13t_disabled_profile_preferences_write_endpoint_contract"]
contract = helper(
    "user-1",
    {
        "preferred_language": "en",
        "study_language": "es",
        "learning_style": "visual",
        "calendar_provider_preference": "google_calendar",
        "voice_enabled": True,
        "auto_listen_enabled": False,
        "role": "admin",
        "unknown_field": "bad",
        "auto_speak_enabled": "yes",
    },
    {"timezone": "America/Denver"},
)

assert contract["source"] == "phase_13t_disabled_profile_preferences_write_endpoint_contract_helper"
assert contract["mode"] == "disabled_profile_preferences_write_endpoint_contract_only"
assert contract["read_only"] is True
assert contract["write_endpoint_contract_only"] is True
assert contract["runtime_action_available"] is False
assert contract["route_wired"] is False
assert contract["frontend_wired"] is False
assert contract["database_wired"] is False
assert contract["database_read_allowed_now"] is False
assert contract["database_write_allowed_now"] is False
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

endpoint = contract["future_write_endpoint_contract"]
assert endpoint["endpoint"] == "/api/profile/preferences"
assert endpoint["method"] == "PATCH"
assert endpoint["current_route_enabled"] is False
assert endpoint["future_route_requires_authenticated_user"] is True
assert endpoint["future_route_uses_backend_api_authority"] is True
assert endpoint["future_route_writes_profile_source_of_truth"] is True
assert endpoint["future_route_uses_field_allowlist"] is True
assert endpoint["future_route_rejects_unknown_fields"] is True
assert endpoint["future_route_rejects_forbidden_fields"] is True
assert endpoint["future_route_validates_enum_values"] is True
assert endpoint["future_route_validates_boolean_values"] is True
assert endpoint["future_route_must_not_return_secrets"] is True
assert endpoint["future_route_must_not_infer_sensitive_attributes"] is True
assert endpoint["future_route_must_not_change_auth_fields"] is True
assert endpoint["future_route_must_not_change_credit_fields"] is True
assert endpoint["future_route_must_not_trigger_model_call"] is True
assert endpoint["future_route_must_not_enqueue_job"] is True
assert endpoint["future_route_must_not_dispatch_worker"] is True

preview = contract["future_write_preview_contract"]
assert preview["status"] == "disabled_contract_only"
assert preview["accepted_preview"]["preferred_language"] == "en"
assert preview["accepted_preview"]["study_language"] == "es"
assert preview["accepted_preview"]["learning_style"] == "visual"
assert preview["accepted_preview"]["calendar_provider_preference"] == "google_calendar"
assert preview["accepted_preview"]["voice_enabled"] is True
assert preview["accepted_preview"]["auto_listen_enabled"] is False
assert preview["rejected_preview"]["role"] == "field_not_allowed"
assert preview["rejected_preview"]["unknown_field"] == "field_not_allowed"
assert preview["rejected_preview"]["auto_speak_enabled"] == "boolean_required"
assert preview["source_tables_future"] == ["app_users", "app_user_preferences"]
assert preview["profile_is_source_of_truth"] is True
assert preview["backend_api_is_authority"] is True
assert preview["frontend_writes_through_backend_only"] is True
assert preview["write_is_not_executed_in_this_phase"] is True

validation = contract["validation_contract"]
assert "preferred_language" in validation["allowed_fields"]
assert "role" in validation["forbidden_fields"]
assert validation["enum_allowlists"]["calendar_provider_preference"] == ["none", "google_calendar", "apple_calendar"]
assert validation["unknown_fields_rejected"] is True
assert validation["partial_patch_allowed"] is True
assert validation["empty_patch_rejected_in_future_route"] is True
assert validation["typed_input_must_remain_available"] is True
assert validation["number_word_equivalence_must_remain_available"] is True

calendar = contract["calendar_boundary_contract"]
assert calendar["allowed_future_calendar_providers"] == ["none", "google_calendar", "apple_calendar"]
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["calendar_event_storage_allowed_in_controller"] is False
assert calendar["calendar_provider_preference_write_allowed"] is True
assert calendar["calendar_provider_connection_required_before_calendar_reads"] is True
assert calendar["calendar_writes_require_explicit_user_request"] is True
assert calendar["calendar_events_must_not_be_stored_by_controller"] is True

voice = contract["voice_boundary_contract"]
assert voice["voice_settings_write_allowed_later"] is True
assert voice["voice_defaults_remain_disabled"] is True
assert voice["auto_listen_default_must_remain_false"] is True
assert voice["auto_speak_default_must_remain_false"] is True
assert voice["browser_microphone_requires_explicit_user_action"] is True
assert voice["typed_input_must_remain_available"] is True

privacy = contract["privacy_permission_contract"]
assert privacy["no_profile_write_in_this_phase"] is True
assert privacy["no_background_personalization_changes"] is True
assert privacy["no_sensitive_attribute_inference"] is True
assert privacy["preferences_must_not_expose_secrets"] is True
assert privacy["write_endpoint_must_not_accept_auth_fields"] is True
assert privacy["write_endpoint_must_not_accept_credit_fields"] is True
assert privacy["write_endpoint_must_not_trigger_model_call"] is True
assert privacy["write_endpoint_must_not_enqueue_job"] is True
assert privacy["write_endpoint_must_not_dispatch_worker"] is True
assert privacy["write_endpoint_must_not_store_calendar_events"] is True
assert privacy["write_endpoint_must_not_store_audio_blobs"] is True

gates = contract["activation_gates"]
assert gates["requires_profile_preference_schema_migration"] is True
assert gates["requires_profile_preference_write_route"] is True
assert gates["requires_authenticated_user_boundary_smoke"] is True
assert gates["requires_field_allowlist_smoke"] is True
assert gates["requires_unknown_field_rejection_smoke"] is True
assert gates["requires_forbidden_field_rejection_smoke"] is True
assert gates["requires_enum_validation_smoke"] is True
assert gates["requires_boolean_validation_smoke"] is True
assert gates["requires_no_secret_exposure_smoke"] is True
assert gates["requires_no_auth_field_change_smoke"] is True
assert gates["requires_no_credit_field_change_smoke"] is True
assert gates["requires_no_calendar_local_storage_smoke"] is True
assert gates["requires_voice_defaults_regression_smoke"] is True
assert gates["requires_typed_input_regression_smoke"] is True

safety = contract["safety"]
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
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13T helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13t_disabled_profile_preferences_write_endpoint_contract_helper' \
  'disabled_profile_preferences_write_endpoint_contract_only' \
  '_stage5p13t_disabled_profile_preferences_write_endpoint_contract' \
  '/api/profile/preferences' \
  'PATCH' \
  'future_route_requires_authenticated_user' \
  'future_route_uses_field_allowlist' \
  'future_route_rejects_unknown_fields' \
  'future_route_rejects_forbidden_fields' \
  'future_route_validates_enum_values' \
  'future_route_validates_boolean_values' \
  'future_route_must_not_change_auth_fields' \
  'future_route_must_not_change_credit_fields' \
  'future_route_must_not_trigger_model_call' \
  'future_route_must_not_enqueue_job' \
  'future_route_must_not_dispatch_worker' \
  'accepted_preview' \
  'rejected_preview' \
  'app_users' \
  'app_user_preferences' \
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
  'enum_allowlists' \
  'boolean_required' \
  'field_not_allowed' \
  'role' \
  'credits' \
  'session_token' \
  'provider_token' \
  'google_calendar' \
  'apple_calendar' \
  'custom local calendar database' \
  'controller-owned calendar event storage' \
  'calendar_events_must_not_be_stored_by_controller' \
  'voice_defaults_remain_disabled' \
  'auto_listen_default_must_remain_false' \
  'auto_speak_default_must_remain_false' \
  'browser_microphone_requires_explicit_user_action' \
  'write_endpoint_must_not_accept_auth_fields' \
  'write_endpoint_must_not_accept_credit_fields' \
  'write_endpoint_must_not_store_calendar_events' \
  'write_endpoint_must_not_store_audio_blobs' \
  'requires_profile_preference_schema_migration' \
  'requires_profile_preference_write_route' \
  'requires_field_allowlist_smoke' \
  'requires_unknown_field_rejection_smoke' \
  'requires_forbidden_field_rejection_smoke' \
  'requires_enum_validation_smoke' \
  'requires_boolean_validation_smoke' \
  'requires_no_auth_field_change_smoke' \
  'requires_no_credit_field_change_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'requires_voice_defaults_regression_smoke' \
  'requires_typed_input_regression_smoke' \
  'no route registration' \
  'no database read' \
  'no database write now' \
  'no profile write' \
  'no database write' \
  'no custom calendar database' \
  'no Ollama direct call'
do
  grep -q "$marker" "docs/${PHASE}.md" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no runtime/route/schema/frontend activation markers in helper ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13t_disabled_profile_preferences_write_endpoint_contract")
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
print("PASS: Phase 13T helper contains no runtime/route/schema/frontend activation markers")
PY

echo
echo "=== verify frontend files unchanged ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13T should not modify frontend files"
  fail=1
else
  echo "PASS: frontend files unchanged"
fi

echo
echo "=== verify no live preference write route/schema/writes were added ==="
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
