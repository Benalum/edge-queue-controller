# Stage 16 FC-O45-E-CI-B — Backend Voice/Speech Contract

Date: 2026-06-26

## Scope

Backend source/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No audio capture. No audio upload. No TTS/STT execution. No package install. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Why this exists

CI-A confirmed that voice is still contract-only. The database already has conservative voice preference fields in app_user_preferences:

- voice_enabled
- listen_enabled
- speak_enabled
- auto_listen_enabled
- auto_speak_enabled

CI-A also confirmed no live voice/speech/audio OpenAPI routes and no installed STT/TTS runtime tools.

## Added backend routes

- GET /api/companion/voice/status
- GET /public/companion/voice/status
- POST /api/companion/voice/action
- POST /public/companion/voice/action

## Current behavior

The routes return a safe contract only.

Current runtime behavior remains disabled:

- current_audio_capture_enabled=false
- current_audio_upload_enabled=false
- current_stt_job_enabled=false
- current_audio_playback_enabled=false
- current_tts_job_enabled=false

Typed input remains the fallback.

## Supported safe actions

- status
- listen_status
- speak_status
- stt_plan
- tts_plan

## Refused runtime actions

The backend refuses runtime audio actions in this phase:

- capture_audio
- upload_audio
- transcribe
- synthesize
- play_audio
- start_background_listening

## Future worker labels

Future, not enabled yet:

- STT future_job_type=stt
- STT future_worker_capability=stt
- STT future_service_label=whisper_asr
- TTS future_job_type=tts
- TTS future_worker_capability=tts
- TTS future_service_label=kokoro_tts
