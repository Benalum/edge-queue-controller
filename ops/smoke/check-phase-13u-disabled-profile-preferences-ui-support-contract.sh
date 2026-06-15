#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13u-disabled-profile-preferences-ui-support-contract"
fail=0

echo "=== ${PHASE}: disabled profile preferences UI support contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous profile/preference contract smokes ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13t-disabled-profile-preferences-write-endpoint-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13t-disabled-profile-preferences-write-endpoint-contract.sh || fail=1
fi
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
echo "=== static Phase 13U markers ==="
for marker in \
  '_stage5p13u_disabled_profile_preferences_ui_support_contract' \
  'phase_13u_disabled_profile_preferences_ui_support_contract_helper' \
  'disabled_profile_preferences_ui_support_contract_only' \
  'ui_support_contract_only' \
  'profile_settings_ui_wired' \
  '/api/profile/preferences' \
  'future_route_required_before_ui_enable' \
  'owned_by_backend_api' \
  'returns_safe_defaults' \
  'must_not_return_secrets' \
  'must_not_infer_sensitive_attributes' \
  'must_not_create_rows' \
  'must_not_write_on_read' \
  'uses_field_allowlist' \
  'rejects_unknown_fields' \
  'rejects_forbidden_fields' \
  'validates_enum_values' \
  'validates_boolean_values' \
  'must_not_change_auth_fields' \
  'must_not_change_credit_fields' \
  'must_not_trigger_model_call' \
  'must_not_enqueue_job' \
  'must_not_dispatch_worker' \
  'current_ui_enabled' \
  'current_frontend_wired' \
  'current_profile_settings_page_changed' \
  'future_profile_settings_ui_allowed' \
  'future_ui_reads_backend_preferences' \
  'future_ui_writes_backend_preferences' \
  'future_ui_uses_safe_defaults_until_read_success' \
  'future_ui_handles_unauthenticated_with_login_redirect' \
  'future_ui_keeps_typed_input_available' \
  'future_ui_does_not_enable_voice_by_default' \
  'future_ui_does_not_start_microphone_automatically' \
  'future_ui_does_not_speak_automatically' \
  'future_ui_does_not_store_calendar_events' \
  'future_ui_does_not_create_custom_calendar_database' \
  'account_language' \
  'study_preferences' \
  'companion_preferences' \
  'voice_preferences' \
  'calendar_preferences' \
  'display_accessibility' \
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
  'listen_enabled' \
  'speak_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'notification_preference' \
  'accessibility_large_text' \
  'accessibility_reduce_motion' \
  'save_button_disabled_in_this_phase' \
  'read_button_disabled_in_this_phase' \
  'form_submission_disabled_in_this_phase' \
  'server_side_validation_required' \
  'unknown_field_rejection_must_be_server_enforced' \
  'forbidden_field_rejection_must_be_server_enforced' \
  'auth_fields_must_not_be_editable' \
  'credit_fields_must_not_be_editable' \
  'provider_tokens_must_not_be_visible' \
  'calendar_events_must_not_be_visible_in_preferences_form' \
  'audio_blobs_must_not_be_visible_in_preferences_form' \
  'google_calendar' \
  'apple_calendar' \
  'custom_local_calendar_database_allowed' \
  'controller_calendar_event_storage_allowed' \
  'calendar_connection_required_before_calendar_reads' \
  'calendar_writes_require_explicit_user_request' \
  'calendar_events_must_not_be_stored_by_controller' \
  'calendar_preferences_ui_must_not_show_raw_provider_tokens' \
  'voice_settings_visible_later' \
  'voice_defaults_remain_disabled' \
  'auto_listen_default_must_remain_false' \
  'auto_speak_default_must_remain_false' \
  'browser_microphone_requires_explicit_user_action' \
  'browser_speech_output_requires_explicit_user_action' \
  'typed_input_must_remain_available' \
  'ui_must_not_expose_auth_fields' \
  'ui_must_not_expose_credit_fields' \
  'ui_must_not_expose_provider_tokens' \
  'ui_must_not_store_calendar_events' \
  'ui_must_not_store_audio_blobs' \
  'ui_must_not_trigger_model_call' \
  'ui_must_not_enqueue_job' \
  'ui_must_not_dispatch_worker' \
  'requires_profile_settings_ui_patch' \
  'requires_authenticated_read_smoke' \
  'requires_authenticated_write_smoke' \
  'requires_safe_default_ui_smoke' \
  'requires_field_allowlist_ui_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'requires_voice_defaults_regression_smoke' \
  'requires_typed_input_regression_smoke' \
  'not_connected_to_live_profile_settings_ui' \
  'no_route_registration' \
  'no_database_write_now' \
  'no_frontend_mutation' \
  'no_custom_calendar_database' \
  'no_browser_microphone_access' \
  'no_browser_speech_output' \
  'no_ollama_direct_call'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing marker $marker"; fail=1; }
done

echo
echo "=== helper count ==="
count="$(grep -c '^def _stage5p13u_disabled_profile_preferences_ui_support_contract(' edge_controller.py || true)"
echo "helper_marker_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13u_disabled_profile_preferences_ui_support_contract(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13u_disabled_profile_preferences_ui_support_contract"]
contract = helper("user-1", {"surface": "profile_settings"})

assert contract["source"] == "phase_13u_disabled_profile_preferences_ui_support_contract_helper"
assert contract["mode"] == "disabled_profile_preferences_ui_support_contract_only"
assert contract["read_only"] is True
assert contract["ui_support_contract_only"] is True
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

read = contract["future_read_endpoint_contract"]
assert read["endpoint"] == "/api/profile/preferences"
assert read["method"] == "GET"
assert read["current_route_enabled"] is False
assert read["future_route_required_before_ui_enable"] is True
assert read["owned_by_backend_api"] is True
assert read["returns_safe_defaults"] is True
assert read["must_not_return_secrets"] is True
assert read["must_not_infer_sensitive_attributes"] is True
assert read["must_not_create_rows"] is True
assert read["must_not_write_on_read"] is True

write = contract["future_write_endpoint_contract"]
assert write["endpoint"] == "/api/profile/preferences"
assert write["method"] == "PATCH"
assert write["current_route_enabled"] is False
assert write["future_route_required_before_ui_enable"] is True
assert write["owned_by_backend_api"] is True
assert write["uses_field_allowlist"] is True
assert write["rejects_unknown_fields"] is True
assert write["rejects_forbidden_fields"] is True
assert write["validates_enum_values"] is True
assert write["validates_boolean_values"] is True
assert write["must_not_change_auth_fields"] is True
assert write["must_not_change_credit_fields"] is True
assert write["must_not_trigger_model_call"] is True
assert write["must_not_enqueue_job"] is True
assert write["must_not_dispatch_worker"] is True

ui = contract["future_ui_state_contract"]
assert ui["current_ui_enabled"] is False
assert ui["current_frontend_wired"] is False
assert ui["current_profile_settings_page_changed"] is False
assert ui["future_profile_settings_ui_allowed"] is True
assert ui["future_ui_reads_backend_preferences"] is True
assert ui["future_ui_writes_backend_preferences"] is True
assert ui["future_ui_uses_safe_defaults_until_read_success"] is True
assert ui["future_ui_handles_unauthenticated_with_login_redirect"] is True
assert ui["future_ui_keeps_typed_input_available"] is True
assert ui["future_ui_does_not_enable_voice_by_default"] is True
assert ui["future_ui_does_not_start_microphone_automatically"] is True
assert ui["future_ui_does_not_speak_automatically"] is True
assert ui["future_ui_does_not_store_calendar_events"] is True
assert ui["future_ui_does_not_create_custom_calendar_database"] is True

form = contract["future_form_contract"]
assert form["save_button_disabled_in_this_phase"] is True
assert form["read_button_disabled_in_this_phase"] is True
assert form["form_submission_disabled_in_this_phase"] is True
assert form["partial_patch_allowed_later"] is True
assert form["dirty_field_tracking_required_later"] is True
assert form["client_side_validation_is_assistive_only"] is True
assert form["server_side_validation_required"] is True
assert form["unknown_field_rejection_must_be_server_enforced"] is True
assert form["forbidden_field_rejection_must_be_server_enforced"] is True
assert form["auth_fields_must_not_be_editable"] is True
assert form["credit_fields_must_not_be_editable"] is True
assert form["provider_tokens_must_not_be_visible"] is True
assert form["calendar_events_must_not_be_visible_in_preferences_form"] is True
assert form["audio_blobs_must_not_be_visible_in_preferences_form"] is True

sections = contract["preference_section_contract"]
assert "preferred_language" in sections["account_language"]
assert "study_language" in sections["account_language"]
assert "learning_style" in sections["study_preferences"]
assert "study_explanation_depth" in sections["study_preferences"]
assert "companion_behavior" in sections["companion_preferences"]
assert "companion_tone" in sections["companion_preferences"]
assert "voice_enabled" in sections["voice_preferences"]
assert "auto_listen_enabled" in sections["voice_preferences"]
assert "calendar_provider_preference" in sections["calendar_preferences"]
assert "accessibility_large_text" in sections["display_accessibility"]

calendar = contract["calendar_ui_boundary_contract"]
assert calendar["allowed_future_calendar_providers"] == ["none", "google_calendar", "apple_calendar"]
assert calendar["calendar_provider_preference_visible_later"] is True
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["controller_calendar_event_storage_allowed"] is False
assert calendar["calendar_connection_required_before_calendar_reads"] is True
assert calendar["calendar_writes_require_explicit_user_request"] is True
assert calendar["calendar_events_must_not_be_stored_by_controller"] is True
assert calendar["calendar_preferences_ui_must_not_show_raw_provider_tokens"] is True

voice = contract["voice_ui_boundary_contract"]
assert voice["voice_settings_visible_later"] is True
assert voice["voice_defaults_remain_disabled"] is True
assert voice["listen_default_must_remain_false"] is True
assert voice["speak_default_must_remain_false"] is True
assert voice["auto_listen_default_must_remain_false"] is True
assert voice["auto_speak_default_must_remain_false"] is True
assert voice["browser_microphone_requires_explicit_user_action"] is True
assert voice["browser_speech_output_requires_explicit_user_action"] is True
assert voice["typed_input_must_remain_available"] is True

privacy = contract["privacy_permission_contract"]
assert privacy["no_profile_write_in_this_phase"] is True
assert privacy["no_background_personalization_changes"] is True
assert privacy["no_sensitive_attribute_inference"] is True
assert privacy["preferences_must_not_expose_secrets"] is True
assert privacy["ui_must_not_expose_auth_fields"] is True
assert privacy["ui_must_not_expose_credit_fields"] is True
assert privacy["ui_must_not_expose_provider_tokens"] is True
assert privacy["ui_must_not_store_calendar_events"] is True
assert privacy["ui_must_not_store_audio_blobs"] is True
assert privacy["ui_must_not_trigger_model_call"] is True
assert privacy["ui_must_not_enqueue_job"] is True
assert privacy["ui_must_not_dispatch_worker"] is True

gates = contract["activation_gates"]
assert gates["requires_profile_preference_schema_migration"] is True
assert gates["requires_profile_preference_read_route"] is True
assert gates["requires_profile_preference_write_route"] is True
assert gates["requires_profile_settings_ui_patch"] is True
assert gates["requires_authenticated_read_smoke"] is True
assert gates["requires_authenticated_write_smoke"] is True
assert gates["requires_safe_default_ui_smoke"] is True
assert gates["requires_field_allowlist_ui_smoke"] is True
assert gates["requires_unknown_field_rejection_ui_smoke"] is True
assert gates["requires_forbidden_field_rejection_ui_smoke"] is True
assert gates["requires_enum_validation_ui_smoke"] is True
assert gates["requires_boolean_validation_ui_smoke"] is True
assert gates["requires_no_auth_field_edit_smoke"] is True
assert gates["requires_no_credit_field_edit_smoke"] is True
assert gates["requires_no_secret_exposure_smoke"] is True
assert gates["requires_no_calendar_local_storage_smoke"] is True
assert gates["requires_voice_defaults_regression_smoke"] is True
assert gates["requires_typed_input_regression_smoke"] is True
assert gates["requires_live_smoke_before_enable"] is True

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
assert safety["no_browser_microphone_access"] is True
assert safety["no_browser_speech_output"] is True
assert safety["no_tool_call"] is True
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13U helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13u_disabled_profile_preferences_ui_support_contract_helper' \
  'disabled_profile_preferences_ui_support_contract_only' \
  '_stage5p13u_disabled_profile_preferences_ui_support_contract' \
  '/api/profile/preferences' \
  'GET' \
  'PATCH' \
  'future_route_required_before_ui_enable' \
  'owned_by_backend_api' \
  'returns_safe_defaults' \
  'must_not_return_secrets' \
  'must_not_infer_sensitive_attributes' \
  'must_not_create_rows' \
  'must_not_write_on_read' \
  'uses_field_allowlist' \
  'rejects_unknown_fields' \
  'rejects_forbidden_fields' \
  'validates_enum_values' \
  'validates_boolean_values' \
  'must_not_change_auth_fields' \
  'must_not_change_credit_fields' \
  'must_not_trigger_model_call' \
  'must_not_enqueue_job' \
  'must_not_dispatch_worker' \
  'current_ui_enabled' \
  'current_frontend_wired' \
  'current_profile_settings_page_changed' \
  'future_profile_settings_ui_allowed' \
  'future_ui_reads_backend_preferences' \
  'future_ui_writes_backend_preferences' \
  'future_ui_uses_safe_defaults_until_read_success' \
  'future_ui_handles_unauthenticated_with_login_redirect' \
  'future_ui_keeps_typed_input_available' \
  'future_ui_does_not_enable_voice_by_default' \
  'future_ui_does_not_start_microphone_automatically' \
  'future_ui_does_not_speak_automatically' \
  'future_ui_does_not_store_calendar_events' \
  'future_ui_does_not_create_custom_calendar_database' \
  'account_language' \
  'study_preferences' \
  'companion_preferences' \
  'voice_preferences' \
  'calendar_preferences' \
  'display_accessibility' \
  'preferred_language' \
  'study_language' \
  'timezone' \
  'locale' \
  'learning_style' \
  'study_explanation_depth' \
  'study_answer_strictness' \
  'study_session_default_mode' \
  'companion_behavior' \
  'companion_tone' \
  'companion_memory_scope' \
  'voice_enabled' \
  'listen_enabled' \
  'speak_enabled' \
  'auto_listen_enabled' \
  'auto_speak_enabled' \
  'calendar_provider_preference' \
  'notification_preference' \
  'accessibility_large_text' \
  'accessibility_reduce_motion' \
  'save_button_disabled_in_this_phase' \
  'read_button_disabled_in_this_phase' \
  'form_submission_disabled_in_this_phase' \
  'server_side_validation_required' \
  'unknown_field_rejection_must_be_server_enforced' \
  'forbidden_field_rejection_must_be_server_enforced' \
  'auth_fields_must_not_be_editable' \
  'credit_fields_must_not_be_editable' \
  'provider_tokens_must_not_be_visible' \
  'calendar_events_must_not_be_visible_in_preferences_form' \
  'audio_blobs_must_not_be_visible_in_preferences_form' \
  'none' \
  'google_calendar' \
  'apple_calendar' \
  'custom local calendar database' \
  'controller calendar event storage' \
  'controller-owned calendar event storage' \
  'calendar_provider_preference_visible_later' \
  'calendar_connection_required_before_calendar_reads' \
  'calendar_writes_require_explicit_user_request' \
  'calendar_events_must_not_be_stored_by_controller' \
  'calendar_preferences_ui_must_not_show_raw_provider_tokens' \
  'voice_settings_visible_later' \
  'voice_defaults_remain_disabled' \
  'auto_listen_default_must_remain_false' \
  'auto_speak_default_must_remain_false' \
  'browser_microphone_requires_explicit_user_action' \
  'browser_speech_output_requires_explicit_user_action' \
  'typed_input_must_remain_available' \
  'ui_must_not_expose_auth_fields' \
  'ui_must_not_expose_credit_fields' \
  'ui_must_not_expose_provider_tokens' \
  'ui_must_not_store_calendar_events' \
  'ui_must_not_store_audio_blobs' \
  'ui_must_not_trigger_model_call' \
  'ui_must_not_enqueue_job' \
  'ui_must_not_dispatch_worker' \
  'requires_profile_preference_schema_migration' \
  'requires_profile_preference_read_route' \
  'requires_profile_preference_write_route' \
  'requires_profile_settings_ui_patch' \
  'requires_authenticated_read_smoke' \
  'requires_authenticated_write_smoke' \
  'requires_safe_default_ui_smoke' \
  'requires_field_allowlist_ui_smoke' \
  'requires_unknown_field_rejection_ui_smoke' \
  'requires_forbidden_field_rejection_ui_smoke' \
  'requires_enum_validation_ui_smoke' \
  'requires_boolean_validation_ui_smoke' \
  'requires_no_auth_field_edit_smoke' \
  'requires_no_credit_field_edit_smoke' \
  'requires_no_secret_exposure_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'requires_voice_defaults_regression_smoke' \
  'requires_typed_input_regression_smoke' \
  'requires_no_login_redirect_regression' \
  'requires_study_ui_preference_read_smoke' \
  'requires_companion_ui_preference_read_smoke' \
  'requires_live_smoke_before_enable' \
  'not_connected_to_live_profile_routes' \
  'not_connected_to_live_profile_settings_ui' \
  'not_connected_to_live_study_ui' \
  'not_connected_to_live_companion_ui' \
  'no route registration' \
  'no database read' \
  'no database write now' \
  'no profile write' \
  'no database write' \
  'no frontend mutation' \
  'no custom calendar database' \
  'no browser microphone access' \
  'no browser speech output' \
  'no Ollama direct call'
do
  grep -q "$marker" "docs/${PHASE}.md" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no runtime/route/schema/frontend/voice activation markers in helper ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13u_disabled_profile_preferences_ui_support_contract")
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
print("PASS: Phase 13U helper contains no runtime/route/schema/frontend/voice activation markers")
PY

echo
echo "=== verify frontend/public/static files were not modified except explicitly allowed read-only Profile UI ==="
frontend_changed="$(
  git diff --name-only -- frontend/study-ui frontend/wrapper-ui public static 2>/dev/null \
    | grep -v '^frontend/wrapper-ui/app.js$' \
    | grep -v '^frontend/wrapper-ui/styles.css$' \
    | grep -v '^frontend/wrapper-ui/index.html$' \
    || true
)"

allowed_profile_ui_changed="$(
  git diff --name-only -- frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css frontend/wrapper-ui/index.html 2>/dev/null \
    || true
)"

if [ -n "$frontend_changed" ]; then
  echo "$frontend_changed"
  echo "FAIL: this profile smoke should not modify unrelated frontend/public/static files"
  fail=1
elif [ -n "$allowed_profile_ui_changed" ]; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE:-0}" = "1" ]; then
    echo "$allowed_profile_ui_changed"
    python3 - <<'PY_PHASE14A_FRONTEND_GUARD'
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

style = Path("frontend/wrapper-ui/styles.css").read_text()
assert "PHASE_14A_PROFILE_PREFERENCES_UI_READ_V1" in style
assert "PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1" in text
assert "PHASE_14F_PROFILE_PREFERENCES_UI_WRITE_V1" in style
assert 'method: "PATCH"' in text
assert "saveProfilePreferencesFromProfilePage" in text
assert ".profile-preferences-card" in style
assert ".profile-preference-list" in style
assert ".profile-preference-row" in style

index = Path("frontend/wrapper-ui/index.html").read_text()
if "frontend/wrapper-ui/index.html" in """${allowed_profile_ui_changed}""":
    assert "v=20260614214f" in index
    assert "/app.js?v=20260614214f" in index
    assert "./styles.css?v=20260614214f" in index
    assert "/study/styles.css?v=20260612000409" in index

print("PASS: read-only Profile preference UI/cache-bust files are live and explicitly allowed")
PY_PHASE14A_FRONTEND_GUARD
  else
    echo "$allowed_profile_ui_changed"
    echo "FAIL: frontend/public/static files changed without EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE=1 or EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE=1, EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE=1, or EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE=1"
    fail=1
  fi
else
  echo "PASS: no frontend/public/static files were changed"
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
  grep -R --exclude='*.bak*' --exclude-dir='__pycache__' -nE '/api/profile/preferences|preferred_language|study_language|learning_style|voice_enabled|calendar_provider_preference' \
    frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css 2>/dev/null \
    || true
)"
if [ -n "$frontend_live_markers" ]; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE:-0}" = "1" ]; then
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
