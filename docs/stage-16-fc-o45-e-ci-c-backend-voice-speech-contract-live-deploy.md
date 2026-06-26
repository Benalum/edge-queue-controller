# Stage 16 FC-O45-E-CI-C — Backend Voice/Speech Contract Live Deploy

Date: 2026-06-26

## Summary

CI-C deployed the backend-only voice/speech contract to CT203 and restarted only the controller service.

No frontend work occurred.

## Live backend deploy

Active CT203 backend file:

    /opt/edge-queue-controller/current/edge_controller.py

Before SHA:

    8b6c0681f16e2d26f49c4a555b60e703aafbda63a1ed05c439f3ecdbdcab3e9f

After SHA:

    464a464d9388088de21a86f1135ba834e84bb5f34efe9f207bb328926c334dd4

Backup path:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-ci-c-backend-voice-speech-contract-deploy-20260626T033722Z

## Service impact

Only this service was restarted:

    edge-queue-controller.service

The controller was active after restart and running on port 7070.

## Live route confirmation

OpenAPI contained:

    /api/companion/voice/status
    /public/companion/voice/status
    /api/companion/voice/action
    /public/companion/voice/action

The Companion Study action endpoint also remained present:

    /api/companion/study/action

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/companion/voice/status
    /public/companion/voice/status
    /api/system/status

The voice status response showed the safe disabled contract:

    feature=companion_voice_speech
    enabled=false
    current_audio_capture_enabled=false
    current_audio_upload_enabled=false
    current_stt_job_enabled=false
    current_audio_playback_enabled=false
    current_tts_job_enabled=false
    no_background_listening=true
    no_auto_capture_on_page_load=true
    typed_input_must_remain_available=true

## Runtime refusal smoke

The runtime action payload:

    {"action":"transcribe"}

returned a refusal:

    ok=false
    error=voice_speech_runtime_disabled
    typed_input_fallback=true
    no_background_listening=true

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no DB write, no schema migration, no job mutation, no result insert, no model/helper/Ollama call, no audio capture, no audio upload, no TTS/STT execution, no worker/timer activation, and no CT/VM restart occurred.
