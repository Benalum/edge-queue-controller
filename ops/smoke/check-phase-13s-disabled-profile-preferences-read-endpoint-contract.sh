#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13s-disabled-profile-preferences-read-endpoint-contract"
fail=0

echo "=== ${PHASE}: disabled profile preferences read endpoint contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous profile/preference contract smokes ==="
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
echo "=== static Phase 13S markers ==="
for marker in \
  '_stage5p13s_disabled_profile_preferences_read_endpoint_contract' \
  'phase_13s_disabled_profile_preferences_read_endpoint_contract_helper' \
  'disabled_profile_preferences_read_endpoint_contract_only' \
  'endpoint_contract_only' \
  'database_read_allowed_now' \
  '/api/profile/preferences' \
  'future_route_requires_authenticated_user' \
  'future_route_returns_safe_defaults' \
  'future_route_must_not_return_secrets' \
  'future_route_must_not_infer_sensitive_attributes' \
  'future_route_must_not_create_missing_rows' \
  'future_route_must_not_write_on_read' \
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
  'read_endpoint_must_not_create_or_update_rows' \
  'read_endpoint_must_not_trigger_model_call' \
  'read_endpoint_must_not_enqueue_job' \
  'read_endpoint_must_not_dispatch_worker' \
  'requires_profile_preference_read_route' \
  'requires_safe_default_response_smoke' \
  'requires_no_write_on_read_smoke' \
  'requires_no_secret_exposure_smoke' \
  'no_route_registration' \
  'no_database_read' \
  'no_custom_calendar_database'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing marker $marker"; fail=1; }
done

echo
echo "=== helper count ==="
count="$(grep -c '^def _stage5p13s_disabled_profile_preferences_read_endpoint_contract(' edge_controller.py || true)"
echo "helper_marker_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13s_disabled_profile_preferences_read_endpoint_contract(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13s_disabled_profile_preferences_read_endpoint_contract"]
contract = helper(
    "user-1",
    {
        "preferred_language": "en",
        "study_language": "es",
        "learning_style": "visual",
        "calendar_provider_preference": "google_calendar",
        "timezone": "America/Denver",
    },
)

assert contract["source"] == "phase_13s_disabled_profile_preferences_read_endpoint_contract_helper"
assert contract["mode"] == "disabled_profile_preferences_read_endpoint_contract_only"
assert contract["read_only"] is True
assert contract["endpoint_contract_only"] is True
assert contract["runtime_action_available"] is False
assert contract["route_wired"] is False
assert contract["frontend_wired"] is False
assert contract["database_wired"] is False
assert contract["database_read_allowed_now"] is False
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

endpoint = contract["future_read_endpoint_contract"]
assert endpoint["endpoint"] == "/api/profile/preferences"
assert endpoint["method"] == "GET"
assert endpoint["current_route_enabled"] is False
assert endpoint["future_route_requires_authenticated_user"] is True
assert endpoint["future_route_uses_backend_api_authority"] is True
assert endpoint["future_route_reads_profile_source_of_truth"] is True
assert endpoint["future_route_returns_safe_defaults"] is True
assert endpoint["future_route_must_not_return_secrets"] is True
assert endpoint["future_route_must_not_infer_sensitive_attributes"] is True
assert endpoint["future_route_must_not_create_missing_rows"] is True
assert endpoint["future_route_must_not_write_on_read"] is True

response = contract["future_response_contract"]
prefs = response["preferences"]
assert prefs["preferred_language"] == "en"
assert prefs["study_language"] == "es"
assert prefs["learning_style"] == "visual"
assert prefs["voice_enabled"] is False
assert prefs["listen_enabled"] is False
assert prefs["speak_enabled"] is False
assert prefs["auto_listen_enabled"] is False
assert prefs["auto_speak_enabled"] is False
assert prefs["timezone"] == "America/Denver"
assert prefs["locale"] == "en-US"
assert prefs["calendar_provider_preference"] == "google_calendar"
assert response["source_tables_future"] == ["app_users", "app_user_preferences"]
assert response["profile_is_source_of_truth"] is True
assert response["backend_api_is_authority"] is True
assert response["frontend_reads_from_backend_only"] is True
assert response["typed_input_must_remain_available"] is True
assert response["number_word_equivalence_must_remain_available"] is True

groups = contract["preference_group_contract"]
assert "preferred_language" in groups["study"]
assert "companion_behavior" in groups["companion"]
assert "voice_enabled" in groups["voice"]
assert "calendar_provider_preference" in groups["calendar"]
assert "timezone" in groups["display_accessibility"]

calendar = contract["calendar_boundary_contract"]
assert calendar["allowed_future_calendar_providers"] == ["none", "google_calendar", "apple_calendar"]
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["calendar_event_storage_allowed_in_controller"] is False
assert calendar["calendar_reads_require_provider_connection"] is True
assert calendar["calendar_writes_require_explicit_user_request"] is True

privacy = contract["privacy_permission_contract"]
assert privacy["no_profile_write_in_this_phase"] is True
assert privacy["no_background_personalization_changes"] is True
assert privacy["no_sensitive_attribute_inference"] is True
assert privacy["preferences_must_not_expose_secrets"] is True
assert privacy["read_endpoint_must_not_create_or_update_rows"] is True
assert privacy["read_endpoint_must_not_trigger_model_call"] is True
assert privacy["read_endpoint_must_not_enqueue_job"] is True
assert privacy["read_endpoint_must_not_dispatch_worker"] is True

gates = contract["activation_gates"]
assert gates["requires_profile_preference_schema_migration"] is True
assert gates["requires_profile_preference_read_route"] is True
assert gates["requires_authenticated_user_boundary_smoke"] is True
assert gates["requires_safe_default_response_smoke"] is True
assert gates["requires_no_write_on_read_smoke"] is True
assert gates["requires_no_unknown_field_response_smoke"] is True
assert gates["requires_no_secret_exposure_smoke"] is True
assert gates["requires_no_calendar_local_storage_smoke"] is True
assert gates["requires_voice_defaults_regression_smoke"] is True
assert gates["requires_typed_input_regression_smoke"] is True

safety = contract["safety"]
assert safety["no_route_registration"] is True
assert safety["no_database_read"] is True
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

print("PASS: dynamic Phase 13S helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13s_disabled_profile_preferences_read_endpoint_contract_helper' \
  'disabled_profile_preferences_read_endpoint_contract_only' \
  '_stage5p13s_disabled_profile_preferences_read_endpoint_contract' \
  '/api/profile/preferences' \
  'GET' \
  'future_route_requires_authenticated_user' \
  'future_route_returns_safe_defaults' \
  'future_route_must_not_return_secrets' \
  'future_route_must_not_infer_sensitive_attributes' \
  'future_route_must_not_create_missing_rows' \
  'future_route_must_not_write_on_read' \
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
  'custom local calendar database' \
  'controller-owned calendar event storage' \
  'calendar_reads_require_provider_connection' \
  'calendar_writes_require_explicit_user_request' \
  'read_endpoint_must_not_create_or_update_rows' \
  'read_endpoint_must_not_trigger_model_call' \
  'read_endpoint_must_not_enqueue_job' \
  'read_endpoint_must_not_dispatch_worker' \
  'requires_profile_preference_schema_migration' \
  'requires_profile_preference_read_route' \
  'requires_authenticated_user_boundary_smoke' \
  'requires_safe_default_response_smoke' \
  'requires_no_write_on_read_smoke' \
  'requires_no_secret_exposure_smoke' \
  'requires_no_calendar_local_storage_smoke' \
  'requires_voice_defaults_regression_smoke' \
  'requires_typed_input_regression_smoke' \
  'no route registration' \
  'no database read' \
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
start = text.index("def _stage5p13s_disabled_profile_preferences_read_endpoint_contract")
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
print("PASS: Phase 13S helper contains no runtime/route/schema/frontend activation markers")
PY

echo
echo "=== verify frontend files were not modified except explicitly allowed read-only Profile UI ==="
frontend_changed="$(
  git diff --name-only -- frontend/study-ui frontend/wrapper-ui 2>/dev/null \
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
  echo "FAIL: this disabled profile contract should not modify unrelated frontend files"
  fail=1
elif [ -n "$allowed_profile_ui_changed" ]; then
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE:-0}" = "1" ]; then
    echo "$allowed_profile_ui_changed"
    python3 - <<'PY_PHASE14A_COMPAT'
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
PY_PHASE14A_COMPAT
  else
    echo "$allowed_profile_ui_changed"
    echo "FAIL: frontend files changed without EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE=1 or EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE=1, EDGE_ALLOW_PROFILE_PREFERENCES_UI_WRITE_LIVE=1, or EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE=1"
    fail=1
  fi
else
  echo "PASS: no frontend files were changed"
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
