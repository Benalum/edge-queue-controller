# Phase 13Q Disabled Profile/Study Preferences Contract

Phase 13Q adds a disabled backend contract for future profile-backed Study and Companion preferences.

This is a planning contract only. It does not enable profile writes, database writes, schema migrations, frontend changes, model calls, queue jobs, worker dispatch, storage writes, file uploads, calendar writes, browser voice behavior, tool calls, or live route behavior.

## Added helper

- `_stage5p13q_disabled_profile_study_preferences_contract`

Helper markers:

- `phase_13q_disabled_profile_study_preferences_contract_helper`
- `disabled_profile_study_preferences_contract_only`

The helper is source-only, disabled, and unwired.

## Source-of-truth rule

Future preferences must follow the platform authority rule:

- profile is the source of truth for user preferences
- backend API is the authority
- frontend reads preferences from backend only
- frontend must not invent trusted preference state
- current route changes are disabled
- current frontend changes are disabled
- current database changes are disabled

Future endpoints may include:

- `/api/profile/preferences`
- `/api/profile/study-preferences`
- `/api/profile/companion-preferences`
- `/api/profile/voice-settings`

Phase 13Q does not add or enable these routes.

## Future preference fields

Later phases may support:

- `preferred_language`
- `study_language`
- `learning_style`
- `study_explanation_depth`
- `study_answer_strictness`
- `study_session_default_mode`
- `companion_behavior`
- `companion_tone`
- `companion_memory_scope`
- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`
- `timezone`
- `locale`
- `calendar_provider_preference`
- `notification_preference`
- `accessibility_large_text`
- `accessibility_reduce_motion`

## Study defaults

Future Study preference defaults should be conservative and predictable:

- `preferred_language: en`
- `study_language: preferred_language or en`
- `learning_style: balanced`
- `study_explanation_depth: normal`
- `study_answer_strictness: balanced`
- `study_session_default_mode: standard_review`
- `allow_number_word_equivalence: true`
- `allow_minor_typo_tolerance: true`
- `typed_input_must_remain_available: true`

The number-word equivalence rule protects examples like `five` matching `5`.

Typed input must remain available even when voice features are added later.

## Companion defaults

Future Companion preference defaults should support Study without making unsafe tool decisions:

- `companion_behavior: supportive_tutor`
- `companion_tone: calm_clear`
- `companion_memory_scope: session_and_profile_approved`
- `mental_health_boundary_copy_required: true`
- `calendar_actions_require_explicit_user_approval: true`
- `tool_actions_require_explicit_user_approval: true`

Companion may explain, coach, and help with Study, but later tool/calendar actions must require explicit user approval.

## Voice defaults

Phase 13Q inherits Phase 13P voice safety.

Future voice preference defaults:

- `voice_enabled: false`
- `listen_enabled: false`
- `speak_enabled: false`
- `auto_listen_enabled: false`
- `auto_speak_enabled: false`
- `push_to_talk_enabled: true`
- `confirm_before_voice_capture: true`
- `inherits_phase_13p_voice_safety: true`

Phase 13Q does not enable microphone capture, speech output, STT, or TTS.

## Calendar preference boundary

The user preference for calendar integration is provider-backed only.

Allowed future calendar providers:

- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller-owned calendar event storage
- calendar writes without explicit user request

Required future behavior:

- calendar reads require provider connection
- calendar writes require explicit user request
- provider connection state must be respected

## Privacy and permission contract

The future preference system must protect user control:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `user_can_change_preferences_later`
- `user_can_disable_voice_later`
- `typed_input_must_remain_available`
- `preferences_must_not_expose_secrets`

This phase records the contract only. It does not infer or write sensitive profile attributes.

## Activation gates

Before live preferences can be enabled, later phases must add and pass:

- `requires_profile_preference_schema_design`
- `requires_profile_preference_read_endpoint`
- `requires_profile_preference_write_endpoint`
- `requires_profile_settings_ui_patch`
- `requires_study_ui_preference_read_smoke`
- `requires_companion_ui_preference_read_smoke`
- `requires_typed_input_regression_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_no_login_redirect_regression`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13Q requires:

- no live profile route connection
- no live Study UI connection
- no live Companion UI connection
- no profile write
- no database write
- no schema migration
- no frontend mutation
- no model invocation
- no queue write
- no worker dispatch
- no storage write
- no file upload
- no calendar write
- no custom calendar database
- no browser microphone access
- no browser speech output
- no tool call
- no Ollama direct call

## Expected repository state before commit

After Phase 13Q Step 2, expected modified files are:

- `edge_controller.py`
- `docs/phase-13q-disabled-profile-study-preferences-contract.md`

The smoke script is added in the next step.
