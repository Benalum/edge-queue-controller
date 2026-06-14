# Phase 13R Disabled Profile Preferences Schema Design

Phase 13R adds a disabled backend schema-design contract for future profile-backed preferences.

This is a planning contract only. It does not create tables, run schema migrations, add columns, write the database, write profile data, add live routes, change frontend behavior, call models, enqueue jobs, dispatch workers, write storage, upload files, write calendars, call tools, or call Ollama.

## Added helper

- `_stage5p13r_disabled_profile_preferences_schema_design`

Helper markers:

- `phase_13r_disabled_profile_preferences_schema_design_helper`
- `disabled_profile_preferences_schema_design_only`

The helper is source-only, disabled, read-only, and unwired.

## Future schema contract

Recommended future table:

- `app_user_preferences`

Future owner table:

- `app_users`

Future primary key:

- `user_id`

Schema authority rules:

- profile is the source of truth
- backend API is the authority
- frontend reads from backend only
- separate preferences table is recommended
- avoid expanding `app_users` for every preference
- current table creation is disabled
- current table migration is disabled
- current column migration is disabled
- current route changes are disabled
- current frontend changes are disabled

Phase 13R does not create `app_user_preferences`.

## Future preference fields

Later phases may support these fields:

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

## Field type contract

Future field types should stay simple and allowlisted:

- `preferred_language: short_text`
- `study_language: short_text`
- `learning_style: enum_text`
- `study_explanation_depth: enum_text`
- `study_answer_strictness: enum_text`
- `study_session_default_mode: enum_text`
- `companion_behavior: enum_text`
- `companion_tone: enum_text`
- `companion_memory_scope: enum_text`
- `voice_enabled: boolean`
- `listen_enabled: boolean`
- `speak_enabled: boolean`
- `auto_listen_enabled: boolean`
- `auto_speak_enabled: boolean`
- `timezone: short_text`
- `locale: short_text`
- `calendar_provider_preference: enum_text`
- `notification_preference: enum_text`
- `accessibility_large_text: boolean`
- `accessibility_reduce_motion: boolean`

## Default value contract

Future default values should be conservative:

- `preferred_language: en`
- `study_language: preferred_language or en`
- `learning_style: balanced`
- `study_explanation_depth: normal`
- `study_answer_strictness: balanced`
- `study_session_default_mode: standard_review`
- `companion_behavior: supportive_tutor`
- `companion_tone: calm_clear`
- `companion_memory_scope: session_and_profile_approved`
- `voice_enabled: false`
- `listen_enabled: false`
- `speak_enabled: false`
- `auto_listen_enabled: false`
- `auto_speak_enabled: false`
- `calendar_provider_preference: none`
- `notification_preference: none`
- `accessibility_large_text: false`
- `accessibility_reduce_motion: false`

Typed input must remain available.

Number-word equivalence must remain available for Study grading examples like `five` matching `5`.

## Validation contract

Future writes must use strict allowlists.

Allowed learning styles:

- `balanced`
- `visual`
- `step_by_step`
- `concise`
- `detailed`

Allowed Study explanation depths:

- `brief`
- `normal`
- `deep`

Allowed Study answer strictness values:

- `lenient`
- `balanced`
- `strict`

Allowed Study session default modes:

- `standard_review`
- `immersive_review`

Allowed Companion behaviors:

- `supportive_tutor`
- `direct_helper`
- `study_coach`

Allowed Companion tones:

- `calm_clear`
- `encouraging`
- `concise`

Allowed Companion memory scopes:

- `session_only`
- `session_and_profile_approved`

Allowed calendar provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller-owned calendar event storage
- unknown preference fields
- sensitive attribute inference
- background personalization changes

## Future endpoint contract

Future endpoints may include:

- `/api/profile/preferences`
- `/api/profile/study-preferences`
- `/api/profile/companion-preferences`
- `/api/profile/voice-settings`

Required future route behavior:

- current routes are disabled
- future writes require authenticated user
- future writes require field allowlist
- future writes must reject unknown fields
- future reads must return safe defaults
- future writes must not expose secrets

## Privacy and permission contract

Phase 13R requires:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `preferences_must_not_expose_secrets`
- `user_can_change_preferences_later`
- `user_can_disable_voice_later`
- `calendar_writes_require_explicit_user_request`
- `tool_actions_require_explicit_user_approval`

## Calendar boundary

Allowed future calendar providers:

- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller-owned calendar event storage
- calendar writes without explicit user request

This matches the project decision that calendar features must be provider-backed only.

## Activation gates

Before live preferences can be enabled, later phases must add and pass:

- `requires_schema_migration_plan`
- `requires_schema_migration_smoke`
- `requires_profile_preference_read_endpoint`
- `requires_profile_preference_write_endpoint`
- `requires_authenticated_user_boundary_smoke`
- `requires_field_allowlist_smoke`
- `requires_unknown_field_rejection_smoke`
- `requires_profile_settings_ui_patch`
- `requires_study_ui_preference_read_smoke`
- `requires_companion_ui_preference_read_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_typed_input_regression_smoke`
- `requires_no_login_redirect_regression`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13R requires:

- no live profile route connection
- no live Study UI connection
- no live Companion UI connection
- no table creation
- no schema migration
- no profile write
- no database write
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

After Phase 13R Step 2, expected modified files are:

- `edge_controller.py`
- `docs/phase-13r-disabled-profile-preferences-schema-design.md`

The smoke script is added in the next step.
