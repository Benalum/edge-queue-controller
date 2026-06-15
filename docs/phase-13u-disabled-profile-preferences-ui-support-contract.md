# Phase 13U Disabled Profile Preferences UI Support Contract

Phase 13U adds a disabled backend contract for future Profile preferences UI support.

This is a planning contract only. It does not register routes, read the database, write the database, create tables, run schema migrations, write profile data, change frontend files, enable Profile settings UI behavior, call models, enqueue jobs, dispatch workers, write storage, upload files, write calendars, call tools, call Ollama, access the browser microphone, or trigger browser speech output.

## Added helper

- `_stage5p13u_disabled_profile_preferences_ui_support_contract`

Helper markers:

- `phase_13u_disabled_profile_preferences_ui_support_contract_helper`
- `disabled_profile_preferences_ui_support_contract_only`

The helper is source-only, disabled, read-only, and unwired.

## Future backend endpoints required before UI enablement

Future read endpoint:

- `/api/profile/preferences`
- `GET`
- `future_route_required_before_ui_enable`
- `owned_by_backend_api`
- `returns_safe_defaults`
- `must_not_return_secrets`
- `must_not_infer_sensitive_attributes`
- `must_not_create_rows`
- `must_not_write_on_read`

Future write endpoint:

- `/api/profile/preferences`
- `PATCH`
- `future_route_required_before_ui_enable`
- `owned_by_backend_api`
- `uses_field_allowlist`
- `rejects_unknown_fields`
- `rejects_forbidden_fields`
- `validates_enum_values`
- `validates_boolean_values`
- `must_not_change_auth_fields`
- `must_not_change_credit_fields`
- `must_not_trigger_model_call`
- `must_not_enqueue_job`
- `must_not_dispatch_worker`

Phase 13U does not add either live endpoint.

## Future UI state contract

Future UI behavior is allowed only after later activation gates pass.

Markers:

- `current_ui_enabled`
- `current_frontend_wired`
- `current_profile_settings_page_changed`
- `future_profile_settings_ui_allowed`
- `future_ui_reads_backend_preferences`
- `future_ui_writes_backend_preferences`
- `future_ui_uses_safe_defaults_until_read_success`
- `future_ui_handles_unauthenticated_with_login_redirect`
- `future_ui_handles_unknown_fields_as_client_error`
- `future_ui_keeps_typed_input_available`
- `future_ui_does_not_enable_voice_by_default`
- `future_ui_does_not_start_microphone_automatically`
- `future_ui_does_not_speak_automatically`
- `future_ui_does_not_store_calendar_events`
- `future_ui_does_not_create_custom_calendar_database`

## Future form sections

Future Profile settings UI may group fields into these sections:

- `account_language`
- `study_preferences`
- `companion_preferences`
- `voice_preferences`
- `calendar_preferences`
- `display_accessibility`

Future account/language fields:

- `preferred_language`
- `study_language`
- `timezone`
- `locale`

Future Study preference fields:

- `learning_style`
- `study_explanation_depth`
- `study_answer_strictness`
- `study_session_default_mode`

Future Companion preference fields:

- `companion_behavior`
- `companion_tone`
- `companion_memory_scope`

Future voice preference fields:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`

Future calendar preference field:

- `calendar_provider_preference`

Future display/accessibility fields:

- `notification_preference`
- `accessibility_large_text`
- `accessibility_reduce_motion`

## Future form behavior contract

Phase 13U keeps all UI behavior disabled.

Markers:

- `save_button_disabled_in_this_phase`
- `read_button_disabled_in_this_phase`
- `form_submission_disabled_in_this_phase`
- `partial_patch_allowed_later`
- `dirty_field_tracking_required_later`
- `client_side_validation_is_assistive_only`
- `server_side_validation_required`
- `unknown_field_rejection_must_be_server_enforced`
- `forbidden_field_rejection_must_be_server_enforced`
- `auth_fields_must_not_be_editable`
- `credit_fields_must_not_be_editable`
- `provider_tokens_must_not_be_visible`
- `calendar_events_must_not_be_visible_in_preferences_form`
- `audio_blobs_must_not_be_visible_in_preferences_form`

## Calendar UI boundary

Allowed future calendar provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller calendar event storage
- controller-owned calendar event storage

Markers:

- `calendar_provider_preference_visible_later`
- `custom_local_calendar_database_allowed`
- `controller_calendar_event_storage_allowed`
- `calendar_connection_required_before_calendar_reads`
- `calendar_writes_require_explicit_user_request`
- `calendar_events_must_not_be_stored_by_controller`
- `calendar_preferences_ui_must_not_show_raw_provider_tokens`

This preserves the project decision that calendar features must be provider-backed only.

## Voice UI boundary

Future voice settings may become visible later, but defaults must remain safe.

Markers:

- `voice_settings_visible_later`
- `voice_defaults_remain_disabled`
- `listen_default_must_remain_false`
- `speak_default_must_remain_false`
- `auto_listen_default_must_remain_false`
- `auto_speak_default_must_remain_false`
- `browser_microphone_requires_explicit_user_action`
- `browser_speech_output_requires_explicit_user_action`
- `typed_input_must_remain_available`

Phase 13U does not add browser microphone behavior or browser speech output.

## Privacy and permission contract

Markers:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `preferences_must_not_expose_secrets`
- `ui_must_not_expose_auth_fields`
- `ui_must_not_expose_credit_fields`
- `ui_must_not_expose_provider_tokens`
- `ui_must_not_store_calendar_events`
- `ui_must_not_store_audio_blobs`
- `ui_must_not_trigger_model_call`
- `ui_must_not_enqueue_job`
- `ui_must_not_dispatch_worker`

## Activation gates

Before a live Profile preferences UI can be enabled, later phases must add and pass:

- `requires_profile_preference_schema_migration`
- `requires_profile_preference_read_route`
- `requires_profile_preference_write_route`
- `requires_profile_settings_ui_patch`
- `requires_authenticated_read_smoke`
- `requires_authenticated_write_smoke`
- `requires_safe_default_ui_smoke`
- `requires_field_allowlist_ui_smoke`
- `requires_unknown_field_rejection_ui_smoke`
- `requires_forbidden_field_rejection_ui_smoke`
- `requires_enum_validation_ui_smoke`
- `requires_boolean_validation_ui_smoke`
- `requires_no_auth_field_edit_smoke`
- `requires_no_credit_field_edit_smoke`
- `requires_no_secret_exposure_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_typed_input_regression_smoke`
- `requires_no_login_redirect_regression`
- `requires_study_ui_preference_read_smoke`
- `requires_companion_ui_preference_read_smoke`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13U requires:

- `not_connected_to_live_profile_routes`
- `not_connected_to_live_profile_settings_ui`
- `not_connected_to_live_study_ui`
- `not_connected_to_live_companion_ui`
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

After Phase 13U Step 2, expected modified files are:

- `edge_controller.py`
- `docs/phase-13u-disabled-profile-preferences-ui-support-contract.md`

The smoke script is added in the next step.
