# Phase 13V Disabled Profile Preferences Contract Rollup

Phase 13V adds a disabled rollup contract for the Profile preferences stack.

This phase summarizes and verifies the disabled contracts from Phase 13P through Phase 13U before any live schema, API route, or UI behavior is enabled.

It is source-only and planning-only. It does not register routes, read the database, write the database, create tables, run schema migrations, write profile data, change frontend files, call models, enqueue jobs, dispatch workers, write storage, upload files, write calendars, call tools, call Ollama, access the browser microphone, or trigger browser speech output.

## Added helper

- `_stage5p13v_disabled_profile_preferences_contract_rollup`

Helper markers:

- `phase_13v_disabled_profile_preferences_contract_rollup_helper`
- `disabled_profile_preferences_contract_rollup_only`
- `rollup_contract_only`

## Component contracts included

The rollup requires these disabled component contracts:

- `phase-13p-disabled-voice-settings-contract`
- `phase-13q-disabled-profile-study-preferences-contract`
- `phase-13r-disabled-profile-preferences-schema-design`
- `phase-13s-disabled-profile-preferences-read-endpoint-contract`
- `phase-13t-disabled-profile-preferences-write-endpoint-contract`
- `phase-13u-disabled-profile-preferences-ui-support-contract`

Required helpers:

- `_stage5p13p_disabled_voice_settings_contract`
- `_stage5p13q_disabled_profile_study_preferences_contract`
- `_stage5p13r_disabled_profile_preferences_schema_design`
- `_stage5p13s_disabled_profile_preferences_read_endpoint_contract`
- `_stage5p13t_disabled_profile_preferences_write_endpoint_contract`
- `_stage5p13u_disabled_profile_preferences_ui_support_contract`

Required statuses:

- `disabled_source_only`
- `all_components_disabled`
- `all_components_source_only`
- `all_components_unwired`

## Stack readiness

Phase 13V records:

- `rollup_complete_for_disabled_contracts`
- `profile_preference_schema_design_present`
- `profile_preference_read_contract_present`
- `profile_preference_write_contract_present`
- `profile_preference_ui_support_contract_present`
- `voice_settings_contract_present`
- `study_preference_contract_present`
- `ready_for_future_live_schema_phase`
- `ready_for_future_live_read_endpoint_phase`
- `ready_for_future_live_write_endpoint_phase`
- `ready_for_future_profile_settings_ui_phase`
- `live_activation_allowed_now`

Only the future live schema phase is marked ready. Live read routes, write routes, and Profile settings UI remain disabled.

## Future activation order

Future live activation order:

1. add `app_user_preferences` schema migration with rollback-safe smoke
2. add authenticated `GET /api/profile/preferences` read endpoint
3. add authenticated `PATCH /api/profile/preferences` write endpoint
4. add server-side validation for allowlists, enums, booleans, and forbidden fields
5. add Profile settings UI read-only display smoke
6. add Profile settings UI edit/save smoke
7. add Study preference consumption smoke
8. add Companion preference consumption smoke
9. add voice defaults regression smoke
10. add calendar provider boundary smoke
11. run final live preference stack rollup before enabling broad use

## Field groups

Account/language:

- `preferred_language`
- `study_language`
- `timezone`
- `locale`

Study preferences:

- `learning_style`
- `study_explanation_depth`
- `study_answer_strictness`
- `study_session_default_mode`

Companion preferences:

- `companion_behavior`
- `companion_tone`
- `companion_memory_scope`

Voice preferences:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`

Calendar preferences:

- `calendar_provider_preference`

Display/accessibility:

- `notification_preference`
- `accessibility_large_text`
- `accessibility_reduce_motion`

## Endpoint rollup

Future read endpoint:

- `/api/profile/preferences`
- `GET`
- `future_routes_require_authenticated_user`
- `future_routes_use_backend_api_authority`
- `future_read_returns_safe_defaults`
- `future_read_must_not_write_on_read`

Future write endpoint:

- `/api/profile/preferences`
- `PATCH`
- `future_write_uses_field_allowlist`
- `future_write_rejects_unknown_fields`
- `future_write_rejects_forbidden_fields`
- `future_write_validates_enum_values`
- `future_write_validates_boolean_values`

Current disabled endpoint markers:

- `current_read_route_enabled`
- `current_write_route_enabled`
- `current_profile_settings_ui_enabled`

Safety markers:

- `future_routes_must_not_return_secrets`
- `future_routes_must_not_change_auth_fields`
- `future_routes_must_not_change_credit_fields`
- `future_routes_must_not_trigger_model_call`
- `future_routes_must_not_enqueue_job`
- `future_routes_must_not_dispatch_worker`

## Calendar rollup

Allowed future calendar provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Calendar boundary markers:

- `calendar_provider_preference_only`
- `custom_local_calendar_database_allowed`
- `controller_calendar_event_storage_allowed`
- `controller_owned_calendar_event_storage_allowed`
- `calendar_provider_connection_required_before_calendar_reads`
- `calendar_writes_require_explicit_user_request`
- `calendar_events_must_not_be_stored_by_controller`
- `provider_tokens_must_not_be_visible`

Calendar remains provider-backed only. No custom local calendar database is allowed.

## Voice rollup

Voice boundary markers:

- `voice_settings_contract_present`
- `voice_defaults_remain_disabled`
- `listen_default_must_remain_false`
- `speak_default_must_remain_false`
- `auto_listen_default_must_remain_false`
- `auto_speak_default_must_remain_false`
- `browser_microphone_requires_explicit_user_action`
- `browser_speech_output_requires_explicit_user_action`
- `typed_input_must_remain_available`

## Privacy and permission rollup

Markers:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `preferences_must_not_expose_secrets`
- `ui_must_not_expose_auth_fields`
- `ui_must_not_expose_credit_fields`
- `ui_must_not_expose_provider_tokens`
- `routes_must_not_accept_auth_fields`
- `routes_must_not_accept_credit_fields`
- `routes_must_not_store_calendar_events`
- `routes_must_not_store_audio_blobs`
- `routes_must_not_trigger_model_call`
- `routes_must_not_enqueue_job`
- `routes_must_not_dispatch_worker`

## Activation gates

Future live work requires:

- `requires_schema_migration_smoke`
- `requires_read_endpoint_smoke`
- `requires_write_endpoint_smoke`
- `requires_authenticated_user_boundary_smoke`
- `requires_safe_defaults_smoke`
- `requires_no_write_on_read_smoke`
- `requires_field_allowlist_smoke`
- `requires_unknown_field_rejection_smoke`
- `requires_forbidden_field_rejection_smoke`
- `requires_enum_validation_smoke`
- `requires_boolean_validation_smoke`
- `requires_no_secret_exposure_smoke`
- `requires_no_auth_field_change_smoke`
- `requires_no_credit_field_change_smoke`
- `requires_profile_settings_ui_smoke`
- `requires_study_ui_preference_read_smoke`
- `requires_companion_ui_preference_read_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_typed_input_regression_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_no_controller_calendar_event_storage_smoke`
- `requires_final_live_rollup_before_enable`

## Disabled safety contract

Phase 13V requires:

- `not_connected_to_live_profile_routes`
- `not_connected_to_live_profile_settings_ui`
- `not_connected_to_live_study_ui`
- `not_connected_to_live_companion_ui`
- `no_route_registration`
- `no_database_read`
- `no_database_write_now`
- `no_table_creation`
- `no_schema_migration`
- `no_profile_write`
- `no_database_write`
- `no_frontend_mutation`
- `no_model_invocation`
- `no_queue_write`
- `no_worker_dispatch`
- `no_storage_write`
- `no_file_upload`
- `no_calendar_write`
- `no_custom_calendar_database`
- `no_controller_calendar_event_storage`
- `no_browser_microphone_access`
- `no_browser_speech_output`
- `no_tool_call`
- `no_ollama_direct_call`

## Smoke strategy

Phase 13V uses the quiet smoke stack runner:

- `ops/smoke/run-quiet.sh`
- `ops/smoke/run-stack-quiet.sh profile`

This avoids recursive repeated smoke output while still capturing full logs under `/tmp/edge-smoke-logs`.
