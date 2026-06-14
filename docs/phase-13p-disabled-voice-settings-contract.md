# Phase 13P Disabled Voice Settings Contract

Phase 13P adds a disabled backend contract for future Study and Companion voice settings.

This is a planning contract only. It does not enable microphone capture, browser speech output, STT, TTS, profile writes, frontend changes, queue jobs, worker dispatch, storage writes, database writes, schema migrations, or live route behavior.

## Added helper

- `_stage5p13p_disabled_voice_settings_contract`

Helper markers:

- `phase_13p_disabled_voice_settings_contract_helper`
- `disabled_voice_settings_contract_only`

The helper is source-only, disabled, and unwired.

## Target future surfaces

When enabled in a later phase, voice settings may affect:

- `frontend/study-ui/app.js`
- `frontend/study-ui/index.html`
- `frontend/study-ui/styles.css`
- `frontend/wrapper-ui/app.js`
- `frontend/wrapper-ui/styles.css`

No frontend files are changed by Phase 13P.

## Future controls

Later UI controls may include:

- `listen_button`
- `stop_listening_button`
- `speak_button`
- `stop_speaking_button`
- `voice_settings_button`
- `voice_mode_status`

These controls must remain disabled until a future live UI phase.

## Future preference fields

Later profile or voice settings may include:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`
- `tts_voice_id`
- `tts_speed`
- `stt_language`
- `push_to_talk_enabled`
- `confirm_before_voice_capture`

Defaults must be conservative:

- `default_voice_enabled: false`
- `auto_listen_default: false`
- `auto_speak_default: false`
- `push_to_talk_default: true`
- `confirm_before_voice_capture_default: true`

Typed input must always remain available.

## STT contract

Future STT support is later-only.

- `future_job_type: stt`
- `future_worker_capability: stt`
- `future_service_label: whisper_asr`
- `audio_upload_required_later`
- `streaming_stt_later`
- `language_from_profile_later`
- `fallback_to_typed_input`
- `current_stt_job_enabled: false`
- `current_audio_capture_enabled: false`

Phase 13P must not capture audio or enqueue STT jobs.

## TTS contract

Future TTS support is later-only.

- `future_job_type: tts`
- `future_worker_capability: tts`
- `future_service_label: kokoro_tts`
- `speak_companion_replies_later`
- `speak_study_card_later`
- `speak_answer_explanation_later`
- `fallback_to_text_output`
- `current_tts_job_enabled: false`
- `current_audio_playback_enabled: false`

Phase 13P must not generate audio or enqueue TTS jobs.

## Future API dependencies

Later phases may use:

- `/api/profile/preferences`
- `/api/profile/voice-settings`
- `/api/jobs`

Future job types:

- `stt`
- `tts`

Future required worker capabilities:

- `stt`
- `tts`

Current backend route changes are disabled.

## Privacy and permission contract

Voice features must be explicit and safe.

- `microphone_requires_explicit_user_action`
- `no_background_listening`
- `no_auto_capture_on_page_load`
- `no_audio_storage_without_later_policy`
- `typed_input_must_remain_available`
- `voice_can_be_disabled_per_user`
- `voice_can_be_disabled_per_session`

The browser microphone must never activate on page load.

## Activation gates

Before any live voice behavior is enabled, later phases must add and pass:

- `requires_profile_preference_schema_design`
- `requires_live_profile_settings_ui_patch`
- `requires_live_study_ui_voice_patch`
- `requires_live_companion_ui_voice_patch`
- `requires_browser_permission_smoke`
- `requires_no_auto_microphone_capture_smoke`
- `requires_typed_input_regression_smoke`
- `requires_stt_worker_capability_smoke`
- `requires_tts_worker_capability_smoke`
- `requires_queue_job_contract_smoke`
- `requires_mobile_layout_smoke`
- `requires_no_login_redirect_regression`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13P requires:

- no live Study UI connection
- no live Companion UI connection
- no live route connection
- no browser microphone access
- no browser speech output
- no TTS runtime change
- no STT runtime change
- no model invocation
- no queue write
- no worker dispatch
- no database write
- no schema migration
- no storage write
- no file upload
- no profile write
- no frontend mutation
- no tool call
- no Ollama direct call
