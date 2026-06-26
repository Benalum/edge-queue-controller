#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CONTROLLER="./edge_controller.py"
DOC="docs/stage-16-fc-o45-e-ci-b-backend-voice-speech-contract.md"

test -f "$CONTROLLER"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CI_B_VOICE_SPEECH_CONTRACT_START" "$CONTROLLER"
grep -Fq "APC_STAGE16_FC_O45_E_CI_B_VOICE_SPEECH_CONTRACT_END" "$CONTROLLER"
grep -Fq '@app.get("/api/companion/voice/status")' "$CONTROLLER"
grep -Fq '@app.get("/public/companion/voice/status")' "$CONTROLLER"
grep -Fq '@app.post("/api/companion/voice/action")' "$CONTROLLER"
grep -Fq '@app.post("/public/companion/voice/action")' "$CONTROLLER"
grep -Fq "current_audio_capture_enabled" "$CONTROLLER"
grep -Fq "current_audio_upload_enabled" "$CONTROLLER"
grep -Fq "current_stt_job_enabled" "$CONTROLLER"
grep -Fq "current_audio_playback_enabled" "$CONTROLLER"
grep -Fq "current_tts_job_enabled" "$CONTROLLER"
grep -Fq "no_background_listening" "$CONTROLLER"
grep -Fq "typed_input_fallback" "$CONTROLLER"
grep -Fq "whisper_asr" "$CONTROLLER"
grep -Fq "kokoro_tts" "$CONTROLLER"

grep -Fq "Backend Voice/Speech Contract" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "GET /api/companion/voice/status" "$DOC"
grep -Fq "POST /api/companion/voice/action" "$DOC"
grep -Fq "current_audio_capture_enabled=false" "$DOC"
grep -Fq "current_tts_job_enabled=false" "$DOC"
grep -Fq "capture_audio" "$DOC"
grep -Fq "start_background_listening" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast
ast.parse(Path("edge_controller.py").read_text())
print("python_ast_parse_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-ci-b backend voice/speech contract source smoke"
