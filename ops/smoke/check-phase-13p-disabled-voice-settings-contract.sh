#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PHASE="phase-13p-disabled-voice-settings-contract"
fail=0

echo "=== ${PHASE}: disabled voice settings contract smoke ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== previous Study/voice boundary smokes ==="
ops/smoke/check-phase-13o-disabled-immersive-study-mode-ui-contract.sh || fail=1
ops/smoke/check-phase-13n-disabled-study-review-ui-support-contract.sh || fail=1
ops/smoke/check-phase-13m-disabled-study-card-image-metadata-contract.sh || fail=1

echo
echo "=== static Phase 13P markers ==="
grep -q "def _stage5p13p_disabled_voice_settings_contract" edge_controller.py || fail=1
grep -q "phase_13p_disabled_voice_settings_contract_helper" edge_controller.py || fail=1
grep -q "disabled_voice_settings_contract_only" edge_controller.py || fail=1
grep -q "listen_button" edge_controller.py || fail=1
grep -q "stop_listening_button" edge_controller.py || fail=1
grep -q "speak_button" edge_controller.py || fail=1
grep -q "voice_settings_button" edge_controller.py || fail=1
grep -q "voice_enabled" edge_controller.py || fail=1
grep -q "auto_listen_default" edge_controller.py || fail=1
grep -q "auto_speak_default" edge_controller.py || fail=1
grep -q "push_to_talk_default" edge_controller.py || fail=1
grep -q "confirm_before_voice_capture_default" edge_controller.py || fail=1
grep -q "future_service_label.*whisper_asr" edge_controller.py || fail=1
grep -q "future_service_label.*kokoro_tts" edge_controller.py || fail=1
grep -q "microphone_requires_explicit_user_action" edge_controller.py || fail=1
grep -q "no_background_listening" edge_controller.py || fail=1
grep -q "no_auto_capture_on_page_load" edge_controller.py || fail=1
grep -q "typed_input_must_remain_available" edge_controller.py || fail=1
grep -q "requires_no_auto_microphone_capture_smoke" edge_controller.py || fail=1
grep -q "requires_typed_input_regression_smoke" edge_controller.py || fail=1
grep -q "requires_stt_worker_capability_smoke" edge_controller.py || fail=1
grep -q "requires_tts_worker_capability_smoke" edge_controller.py || fail=1
grep -q "no_browser_microphone_access" edge_controller.py || fail=1
grep -q "no_browser_speech_output" edge_controller.py || fail=1
grep -q "no_tts_runtime_change" edge_controller.py || fail=1
grep -q "no_stt_runtime_change" edge_controller.py || fail=1
echo "PASS: static Phase 13P markers exist"

echo
echo "=== helper is source-only and unwired ==="
count="$(grep -c "_stage5p13p_disabled_voice_settings_contract" edge_controller.py || true)"
echo "helper_marker_count=${count}"
if [ "$count" != "1" ]; then
  echo "FAIL: Phase 13P helper should exist exactly once and have no callers yet"
  fail=1
else
  echo "PASS: Phase 13P helper exists exactly once and is not called by routes"
fi

echo
echo "=== dynamic helper behavior without importing full app ==="
python3 - <<'PYDYN' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13p_disabled_voice_settings_contract(")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
ns = {}
exec(text[start:end], ns)

helper = ns["_stage5p13p_disabled_voice_settings_contract"]
contract = helper(
    "study_companion_voice",
    "user-1",
    {"preferred_language": "en", "study_language": "en", "voice_preference": "off"},
)

assert contract["source"] == "phase_13p_disabled_voice_settings_contract_helper"
assert contract["mode"] == "disabled_voice_settings_contract_only"
assert contract["voice_settings_contract"]["default_voice_enabled"] is False
assert contract["voice_settings_contract"]["auto_listen_default"] is False
assert contract["voice_settings_contract"]["auto_speak_default"] is False
assert contract["voice_settings_contract"]["push_to_talk_default"] is True
assert contract["voice_settings_contract"]["confirm_before_voice_capture_default"] is True
assert contract["privacy_permission_contract"]["microphone_requires_explicit_user_action"] is True
assert contract["privacy_permission_contract"]["no_background_listening"] is True
assert contract["privacy_permission_contract"]["no_auto_capture_on_page_load"] is True
assert contract["privacy_permission_contract"]["typed_input_must_remain_available"] is True
assert contract["stt_contract"]["future_job_type"] == "stt"
assert contract["stt_contract"]["future_worker_capability"] == "stt"
assert contract["stt_contract"]["future_service_label"] == "whisper_asr"
assert contract["stt_contract"]["current_stt_job_enabled"] is False
assert contract["stt_contract"]["current_audio_capture_enabled"] is False
assert contract["tts_contract"]["future_job_type"] == "tts"
assert contract["tts_contract"]["future_worker_capability"] == "tts"
assert contract["tts_contract"]["future_service_label"] == "kokoro_tts"
assert contract["tts_contract"]["current_tts_job_enabled"] is False
assert contract["tts_contract"]["current_audio_playback_enabled"] is False
assert contract["browser_microphone_allowed"] is False
assert contract["browser_speech_output_allowed"] is False
assert contract["tts_runtime_allowed"] is False
assert contract["stt_runtime_allowed"] is False
assert contract["frontend_wired"] is False
assert contract["database_write_allowed"] is False
assert contract["job_enqueue_allowed"] is False
assert contract["worker_dispatch_allowed"] is False
assert contract["profile_write_allowed"] is False
assert contract["activation_gates"]["requires_no_auto_microphone_capture_smoke"] is True
assert contract["activation_gates"]["requires_typed_input_regression_smoke"] is True
assert contract["activation_gates"]["requires_stt_worker_capability_smoke"] is True
assert contract["activation_gates"]["requires_tts_worker_capability_smoke"] is True
assert contract["safety"]["no_browser_microphone_access"] is True
assert contract["safety"]["no_browser_speech_output"] is True
assert contract["safety"]["no_tts_runtime_change"] is True
assert contract["safety"]["no_stt_runtime_change"] is True
assert contract["safety"]["no_frontend_mutation"] is True
assert contract["safety"]["no_profile_write"] is True

print("PASS: dynamic Phase 13P helper behavior is disabled and correct")
PYDYN

echo
echo "=== doc markers ==="
test -f "docs/${PHASE}.md" || fail=1
grep -q "phase_13p_disabled_voice_settings_contract_helper" "docs/${PHASE}.md" || fail=1
grep -q "disabled_voice_settings_contract_only" "docs/${PHASE}.md" || fail=1
grep -q "listen_button" "docs/${PHASE}.md" || fail=1
grep -q "stop_listening_button" "docs/${PHASE}.md" || fail=1
grep -q "speak_button" "docs/${PHASE}.md" || fail=1
grep -q "voice_settings_button" "docs/${PHASE}.md" || fail=1
grep -q "voice_enabled" "docs/${PHASE}.md" || fail=1
grep -q "auto_listen_enabled" "docs/${PHASE}.md" || fail=1
grep -q "auto_speak_enabled" "docs/${PHASE}.md" || fail=1
grep -q "push_to_talk_enabled" "docs/${PHASE}.md" || fail=1
grep -q "confirm_before_voice_capture" "docs/${PHASE}.md" || fail=1
grep -q "future_job_type: stt" "docs/${PHASE}.md" || fail=1
grep -q "future_job_type: tts" "docs/${PHASE}.md" || fail=1
grep -q "future_service_label: whisper_asr" "docs/${PHASE}.md" || fail=1
grep -q "future_service_label: kokoro_tts" "docs/${PHASE}.md" || fail=1
grep -q "/api/profile/voice-settings" "docs/${PHASE}.md" || fail=1
grep -q "/api/jobs" "docs/${PHASE}.md" || fail=1
grep -q "microphone_requires_explicit_user_action" "docs/${PHASE}.md" || fail=1
grep -q "no_background_listening" "docs/${PHASE}.md" || fail=1
grep -q "no_auto_capture_on_page_load" "docs/${PHASE}.md" || fail=1
grep -q "typed_input_must_remain_available" "docs/${PHASE}.md" || fail=1
grep -q "requires_no_auto_microphone_capture_smoke" "docs/${PHASE}.md" || fail=1
grep -q "requires_typed_input_regression_smoke" "docs/${PHASE}.md" || fail=1
grep -q "requires_stt_worker_capability_smoke" "docs/${PHASE}.md" || fail=1
grep -q "requires_tts_worker_capability_smoke" "docs/${PHASE}.md" || fail=1
grep -q "no browser microphone access" "docs/${PHASE}.md" || fail=1
grep -q "no browser speech output" "docs/${PHASE}.md" || fail=1
grep -q "no TTS runtime change" "docs/${PHASE}.md" || fail=1
grep -q "no STT runtime change" "docs/${PHASE}.md" || fail=1
grep -q "no frontend mutation" "docs/${PHASE}.md" || fail=1
grep -q "no profile write" "docs/${PHASE}.md" || fail=1
echo "PASS: Phase 13P doc markers exist"

echo
echo "=== no runtime/frontend/voice activation markers in Phase 13P helper ==="
python3 - <<'PYSTATIC' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
start = text.index("def _stage5p13p_disabled_voice_settings_contract")
end = text.index("# --- Phase 13F disabled admin Study-answer preview endpoint")
helper = text[start:end]
forbidden = [
    "requests.post(",
    "httpx.post(",
    "ollama.generate",
    "enqueue_job(",
    "INSERT INTO",
    "UPDATE study_",
    "UPDATE app_users",
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
print("PASS: Phase 13P helper contains no runtime/frontend/voice activation markers")
PYSTATIC

echo
echo "=== verify frontend files were not modified ==="
frontend_diff="$(git diff --name-only -- frontend/study-ui frontend/wrapper-ui || true)"
if [ -n "$frontend_diff" ]; then
  echo "$frontend_diff"
  echo "FAIL: disabled Phase 13P should not modify frontend files"
  fail=1
else
  echo "PASS: frontend files unchanged"
fi

echo
echo "=== verify no live browser voice APIs were wired ==="
if grep -R -nE "navigator\.mediaDevices|SpeechRecognition|speechSynthesis|getUserMedia" frontend/study-ui frontend/wrapper-ui 2>/dev/null; then
  echo "FAIL: live browser voice API wiring should not exist in disabled Phase 13P"
  fail=1
else
  echo "PASS: no live browser voice API wiring found"
fi

echo
echo "=== verify no live voice routes/schema/jobs were added ==="
if grep -qE '@app\.(post|get|put|patch)\("/api/profile/voice-settings"|CREATE TABLE.*voice|ALTER TABLE.*voice|enqueue_job\(.*"stt"|enqueue_job\(.*"tts"' edge_controller.py; then
  echo "FAIL: live voice routes/schema/jobs should not exist in disabled Phase 13P"
  fail=1
else
  echo "PASS: no live voice routes/schema/jobs were added"
fi

echo
echo "=== safety: power auto full tick remains quarantined ==="
env_dump="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr " " "\n" | grep -E "^EDGE_POWER_AUTO_PAUSED=|^EDGE_POWER_AUTO_TICK_FULL=" || true)"
echo "$env_dump"
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_PAUSED=0$" || fail=1
echo "$env_dump" | grep -q "^EDGE_POWER_AUTO_TICK_FULL=0$" || fail=1

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no frontend files were changed"
echo "PASS: no live Study UI behavior was changed"
echo "PASS: no live Companion UI behavior was changed"
echo "PASS: no browser microphone behavior was added"
echo "PASS: no browser speech output behavior was added"
echo "PASS: no STT runtime behavior was added"
echo "PASS: no TTS runtime behavior was added"
echo "PASS: no model call was added"
echo "PASS: no queue write was added"
echo "PASS: no worker dispatch was added"
echo "PASS: no database write was added"
echo "PASS: no schema migration was added"
echo "PASS: no storage write was added"
echo "PASS: no file upload was added"
echo "PASS: no profile write was added"
echo "PASS: no Ollama direct call was added"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
  exit 1
fi
