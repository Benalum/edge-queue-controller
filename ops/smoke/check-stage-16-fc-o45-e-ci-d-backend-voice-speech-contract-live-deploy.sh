#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-ci-c-backend-voice-speech-contract-live-deploy.md"

test -f "$DOC"

grep -Fq "Backend Voice/Speech Contract Live Deploy" "$DOC"
grep -Fq "/opt/edge-queue-controller/current/edge_controller.py" "$DOC"
grep -Fq "8b6c0681f16e2d26f49c4a555b60e703aafbda63a1ed05c439f3ecdbdcab3e9f" "$DOC"
grep -Fq "464a464d9388088de21a86f1135ba834e84bb5f34efe9f207bb328926c334dd4" "$DOC"
grep -Fq "stage-16-fc-o45-e-ci-c-backend-voice-speech-contract-deploy-20260626T033722Z" "$DOC"
grep -Fq "edge-queue-controller.service" "$DOC"
grep -Fq "port 7070" "$DOC"
grep -Fq "/api/companion/voice/status" "$DOC"
grep -Fq "/public/companion/voice/status" "$DOC"
grep -Fq "/api/companion/voice/action" "$DOC"
grep -Fq "/public/companion/voice/action" "$DOC"
grep -Fq "/api/companion/study/action" "$DOC"
grep -Fq "enabled=false" "$DOC"
grep -Fq "current_audio_capture_enabled=false" "$DOC"
grep -Fq "current_stt_job_enabled=false" "$DOC"
grep -Fq "current_tts_job_enabled=false" "$DOC"
grep -Fq "voice_speech_runtime_disabled" "$DOC"
grep -Fq "No frontend patch" "$DOC"

echo "PASS stage-16-fc-o45-e-ci-d backend voice/speech deploy record smoke"
