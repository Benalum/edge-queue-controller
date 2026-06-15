#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13q-disabled-profile-study-preferences-contract"
fail=0

echo "=== ${PHASE}: disabled profile/study preferences contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous contract smokes ==="
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13p-disabled-voice-settings-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13p-disabled-voice-settings-contract.sh || fail=1
fi
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13o-disabled-immersive-study-mode-ui-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13o-disabled-immersive-study-mode-ui-contract.sh || fail=1
fi
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13n-disabled-study-review-ui-support-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13n-disabled-study-review-ui-support-contract.sh || fail=1
fi
if [ "${EDGE_SMOKE_SKIP_DEPS:-0}" = "1" ]; then
  echo "SKIP: dependency ops/smoke/check-phase-13m-disabled-study-card-image-metadata-contract.sh (EDGE_SMOKE_SKIP_DEPS=1)"
else
  ops/smoke/check-phase-13m-disabled-study-card-image-metadata-contract.sh || fail=1
fi

echo
echo "=== static Phase 13Q markers ==="
for marker in \
  '_stage5p13q_disabled_profile_study_preferences_contract' \
  'phase_13q_disabled_profile_study_preferences_contract_helper' \
  'disabled_profile_study_preferences_contract_only' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'study_explanation_depth' \
  'study_answer_strictness' \
  'study_session_default_mode' \
  'companion_behavior' \
  'companion_tone' \
  'companion_memory_scope' \
  'allow_number_word_equivalence' \
  'typed_input_must_remain_available' \
  'calendar_actions_require_explicit_user_approval' \
  'tool_actions_require_explicit_user_approval' \
  'inherits_phase_13p_voice_safety' \
  'google_calendar' \
  'apple_calendar' \
  'custom_local_calendar_database_allowed' \
  'calendar_event_storage_allowed_in_controller' \
  'requires_no_calendar_local_storage_smoke' \
  'requires_voice_defaults_regression_smoke' \
  'no_custom_calendar_database'
do
  grep -q "$marker" edge_controller.py || { echo "FAIL: missing marker $marker"; fail=1; }
done

echo
echo "=== helper count ==="
count="$(grep -c '^def _stage5p13q_disabled_profile_study_preferences_contract(' edge_controller.py || true)"
echo "helper_marker_count=${count}"
test "$count" = "1" || fail=1

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13q_disabled_profile_study_preferences_contract(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13q_disabled_profile_study_preferences_contract"]
contract = helper(
    "user-1",
    {
        "preferred_language": "en",
        "study_language": "es",
        "learning_style": "visual",
        "companion_behavior": "supportive_tutor",
        "calendar_provider_preference": "google_calendar",
    },
    "profile_study_preferences",
)

assert contract["source"] == "phase_13q_disabled_profile_study_preferences_contract_helper"
assert contract["mode"] == "disabled_profile_study_preferences_contract_only"
assert contract["read_only"] is True
assert contract["network_calls"] is False
assert contract["frontend_wired"] is False
assert contract["route_wired"] is False
assert contract["database_wired"] is False
assert contract["profile_write_allowed"] is False
assert contract["database_write_allowed"] is False
assert contract["schema_migration_allowed"] is False
assert contract["frontend_mutation_allowed"] is False
assert contract["model_call_allowed"] is False
assert contract["job_enqueue_allowed"] is False
assert contract["worker_dispatch_allowed"] is False
assert contract["calendar_write_allowed"] is False

prefs = contract["profile_study_preferences_contract"]
assert prefs["profile_is_source_of_truth"] is True
assert prefs["backend_api_is_authority"] is True
assert prefs["frontend_reads_from_backend_only"] is True
assert prefs["current_route_change_enabled"] is False
assert prefs["current_frontend_change_enabled"] is False
assert prefs["current_database_change_enabled"] is False

study = contract["study_preference_defaults"]
assert study["preferred_language"] == "en"
assert study["study_language"] == "es"
assert study["learning_style"] == "visual"
assert study["allow_number_word_equivalence"] is True
assert study["allow_minor_typo_tolerance"] is True
assert study["typed_input_must_remain_available"] is True

companion = contract["companion_preference_defaults"]
assert companion["calendar_actions_require_explicit_user_approval"] is True
assert companion["tool_actions_require_explicit_user_approval"] is True

voice = contract["voice_preference_defaults"]
assert voice["voice_enabled"] is False
assert voice["auto_listen_enabled"] is False
assert voice["auto_speak_enabled"] is False
assert voice["inherits_phase_13p_voice_safety"] is True

calendar = contract["calendar_preference_contract"]
assert calendar["allowed_future_calendar_providers"] == ["google_calendar", "apple_calendar"]
assert calendar["custom_local_calendar_database_allowed"] is False
assert calendar["calendar_event_storage_allowed_in_controller"] is False
assert calendar["calendar_writes_require_explicit_user_request"] is True

safety = contract["safety"]
assert safety["no_profile_write"] is True
assert safety["no_database_write"] is True
assert safety["no_schema_migration"] is True
assert safety["no_frontend_mutation"] is True
assert safety["no_model_invocation"] is True
assert safety["no_queue_write"] is True
assert safety["no_worker_dispatch"] is True
assert safety["no_calendar_write"] is True
assert safety["no_custom_calendar_database"] is True
assert safety["no_ollama_direct_call"] is True

print("PASS: dynamic Phase 13Q helper behavior is disabled and correct")
PY

echo
echo "=== doc markers ==="
for marker in \
  'phase_13q_disabled_profile_study_preferences_contract_helper' \
  'disabled_profile_study_preferences_contract_only' \
  '_stage5p13q_disabled_profile_study_preferences_contract' \
  '/api/profile/preferences' \
  '/api/profile/study-preferences' \
  '/api/profile/companion-preferences' \
  '/api/profile/voice-settings' \
  'preferred_language' \
  'study_language' \
  'learning_style' \
  'allow_number_word_equivalence: true' \
  'typed_input_must_remain_available: true' \
  'google_calendar' \
  'apple_calendar' \
  'custom local calendar database' \
  'controller-owned calendar event storage' \
  'requires_no_calendar_local_storage_smoke' \
  'no profile write' \
  'no custom calendar database' \
  'no Ollama direct call'
do
  grep -q "$marker" "docs/${PHASE}.md" || { echo "FAIL: missing doc marker $marker"; fail=1; }
done

echo
echo "=== no runtime/profile/frontend activation markers in helper ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13q_disabled_profile_study_preferences_contract")
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
print("PASS: Phase 13Q helper contains no runtime/profile/frontend activation markers")
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
  if [ "${EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE:-0}" = "1" ] || [ "${EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE:-0}" = "1" ]; then
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
    'method: "PATCH"',
    "PATCH /api/profile/preferences",
    "profilePreferencesSave",
    "saveProfilePreferences",
    "data-profile-preferences-save",
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
assert ".profile-preferences-card" in style
assert ".profile-preference-list" in style
assert ".profile-preference-row" in style

index = Path("frontend/wrapper-ui/index.html").read_text()
if "frontend/wrapper-ui/index.html" in """${allowed_profile_ui_changed}""":
    assert "v=20260614214d" in index
    assert "/app.js?v=20260614214d" in index
    assert "./styles.css?v=20260614214d" in index
    assert "/study/styles.css?v=20260612000409" in index

print("PASS: read-only Profile preference UI/cache-bust files are live and explicitly allowed")
PY_PHASE14A_COMPAT
  else
    echo "$allowed_profile_ui_changed"
    echo "FAIL: frontend files changed without EDGE_ALLOW_PROFILE_PREFERENCES_UI_READ_LIVE=1 or EDGE_ALLOW_WRAPPER_CACHE_BUST_LIVE=1"
    fail=1
  fi
else
  echo "PASS: no frontend files were changed"
fi

echo
echo "=== verify no live profile routes/schema/writes were added ==="
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
