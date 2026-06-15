# Phase 13T Disabled Profile Preferences Write Endpoint Contract

Phase 13T adds a disabled backend contract for a future profile preferences write endpoint.

This is a planning contract only. It does not register a route, read the database, write the database, create tables, run schema migrations, write profile data, change frontend behavior, call models, enqueue jobs, dispatch workers, write storage, upload files, write calendars, call tools, or call Ollama.

## Added helper

- `_stage5p13t_disabled_profile_preferences_write_endpoint_contract`

Helper markers:

- `phase_13t_disabled_profile_preferences_write_endpoint_contract_helper`
- `disabled_profile_preferences_write_endpoint_contract_only`

The helper is source-only, disabled, read-only, and unwired.

## Future write endpoint contract

Future endpoint:

- `/api/profile/preferences`

Future method:

- `PATCH`

Required future behavior:

- `future_route_requires_authenticated_user: true`
- `future_route_uses_backend_api_authority: true`
- `future_route_writes_profile_source_of_truth: true`
- `future_route_uses_field_allowlist: true`
- `future_route_rejects_unknown_fields: true`
- `future_route_rejects_forbidden_fields: true`
- `future_route_validates_enum_values: true`
- `future_route_validates_boolean_values: true`
- `future_route_must_not_return_secrets: true`
- `future_route_must_not_infer_sensitive_attributes: true`
- `future_route_must_not_change_auth_fields: true`
- `future_route_must_not_change_credit_fields: true`
- `future_route_must_not_trigger_model_call: true`
- `future_route_must_not_enqueue_job: true`
- `future_route_must_not_dispatch_worker: true`

Current route behavior:

- `current_route_enabled: false`

Phase 13T does not add a live `/api/profile/preferences` write route.

## Future write preview contract

The disabled helper returns a preview only:

- `accepted_preview`
- `rejected_preview`
- `available_fields`
- `forbidden_fields`
- `source_tables_future`
- `profile_is_source_of_truth`
- `backend_api_is_authority`
- `frontend_writes_through_backend_only`
- `write_is_not_executed_in_this_phase`

Future source tables:

- `app_users`
- `app_user_preferences`

Phase 13T does not read or write either table.

## Future preference fields

Future writes may allow these fields only:

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

Allowed notification preferences:

- `none`
- `email`
- `in_app`

Boolean fields must be booleans:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`
- `accessibility_large_text`
- `accessibility_reduce_motion`

Future validation rules:

- `unknown_fields_rejected: true`
- `partial_patch_allowed: true`
- `empty_patch_rejected_in_future_route: true`
- `typed_input_must_remain_available: true`
- `number_word_equivalence_must_remain_available: true`

## Forbidden fields

Future preference writes must reject auth, account, billing, credit, session, provider-token, calendar-event, audio, model, worker, and admin fields.

Examples:

- `id`
- `user_id`
- `email`
- `password`
- `password_hash`
- `role`
- `plan`
- `credits`
- `free_local_balance`
- `paid_balance`
- `session_token`
- `csrf_token`
- `provider_token`
- `oauth_token`
- `calendar_event`
- `calendar_events`
- `audio_blob`
- `transcript`
- `model`
- `worker_id`
- `admin`

Preview rejection examples:

- `field_not_allowed`
- `enum_value_not_allowed`
- `boolean_required`
- `text_required`

## Calendar boundary

Allowed future calendar provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller-owned calendar event storage

Future calendar boundary rules:

- `calendar_provider_preference_write_allowed: true`
- `calendar_provider_connection_required_before_calendar_reads: true`
- `calendar_writes_require_explicit_user_request: true`
- `calendar_events_must_not_be_stored_by_controller: true`

This preserves the project decision that calendar features must be provider-backed only.

## Voice boundary

Future voice preference writes may be allowed later, but defaults must remain safe:

- `voice_settings_write_allowed_later: true`
- `voice_defaults_remain_disabled: true`
- `auto_listen_default_must_remain_false: true`
- `auto_speak_default_must_remain_false: true`
- `browser_microphone_requires_explicit_user_action: true`
- `typed_input_must_remain_available: true`

Phase 13T does not add browser microphone behavior or browser speech output.

## Privacy and permission contract

Phase 13T requires:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `preferences_must_not_expose_secrets`
- `write_endpoint_must_not_accept_auth_fields`
- `write_endpoint_must_not_accept_credit_fields`
- `write_endpoint_must_not_trigger_model_call`
- `write_endpoint_must_not_enqueue_job`
- `write_endpoint_must_not_dispatch_worker`
- `write_endpoint_must_not_store_calendar_events`
- `write_endpoint_must_not_store_audio_blobs`

## Activation gates

Before a live write endpoint can be enabled, later phases must add and pass:

- `requires_profile_preference_schema_migration`
- `requires_profile_preference_write_route`
- `requires_authenticated_user_boundary_smoke`
- `requires_field_allowlist_smoke`
- `requires_unknown_field_rejection_smoke`
- `requires_forbidden_field_rejection_smoke`
- `requires_enum_validation_smoke`
- `requires_boolean_validation_smoke`
- `requires_no_secret_exposure_smoke`
- `requires_no_auth_field_change_smoke`
- `requires_no_credit_field_change_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_typed_input_regression_smoke`
- `requires_profile_settings_ui_patch`
- `requires_study_ui_preference_write_smoke`
- `requires_companion_ui_preference_write_smoke`
- `requires_no_login_redirect_regression`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13T requires:

- no live profile route connection
- no live Study UI connection
- no live Companion UI connection
- no route registration
- no database read
- no database write now
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

After Phase 13T Step 2, expected modified files are:

- `edge_controller.py`
- `docs/phase-13t-disabled-profile-preferences-write-endpoint-contract.md`

The smoke script is added in the next step.

## Verification markers

These literal markers are included for smoke verification:

- `enum_allowlists`
- `boolean_required`
- `field_not_allowed`
- `future_route_uses_field_allowlist`
- `future_route_rejects_unknown_fields`
- `future_route_rejects_forbidden_fields`
- `future_route_validates_enum_values`
- `future_route_validates_boolean_values`
- `write_endpoint_must_not_accept_auth_fields`
- `write_endpoint_must_not_accept_credit_fields`
- `write_endpoint_must_not_store_calendar_events`
- `write_endpoint_must_not_store_audio_blobs`
- `requires_field_allowlist_smoke`
- `requires_unknown_field_rejection_smoke`
- `requires_forbidden_field_rejection_smoke`
- `requires_enum_validation_smoke`
- `requires_boolean_validation_smoke`
- `requires_no_auth_field_change_smoke`
- `requires_no_credit_field_change_smoke`
