# Phase 13S Disabled Profile Preferences Read Endpoint Contract

Phase 13S adds a disabled backend contract for a future profile preferences read endpoint.

This is a planning contract only. It does not register a route, read the database, write the database, create tables, run schema migrations, write profile data, change frontend behavior, call models, enqueue jobs, dispatch workers, write storage, upload files, write calendars, call tools, or call Ollama.

## Added helper

- `_stage5p13s_disabled_profile_preferences_read_endpoint_contract`

Helper markers:

- `phase_13s_disabled_profile_preferences_read_endpoint_contract_helper`
- `disabled_profile_preferences_read_endpoint_contract_only`

The helper is source-only, disabled, read-only, and unwired.

## Future read endpoint contract

Future endpoint:

- `/api/profile/preferences`

Future method:

- `GET`

Required future behavior:

- `future_route_requires_authenticated_user: true`
- `future_route_uses_backend_api_authority: true`
- `future_route_reads_profile_source_of_truth: true`
- `future_route_returns_safe_defaults: true`
- `future_route_must_not_return_secrets: true`
- `future_route_must_not_infer_sensitive_attributes: true`
- `future_route_must_not_create_missing_rows: true`
- `future_route_must_not_write_on_read: true`

Current route behavior:

- `current_route_enabled: false`

Phase 13S does not add a live `/api/profile/preferences` route.

## Future response contract

Future response shape should include:

- `preferences`
- `available_fields`
- `source_tables_future`
- `profile_is_source_of_truth`
- `backend_api_is_authority`
- `frontend_reads_from_backend_only`
- `typed_input_must_remain_available`
- `number_word_equivalence_must_remain_available`

Future source tables:

- `app_users`
- `app_user_preferences`

Phase 13S does not read either table.

## Future preference fields

The future read response may include these allowlisted fields:

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

## Safe defaults

Future safe defaults should remain conservative:

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
- `timezone: profile_default`
- `locale: en-US`
- `calendar_provider_preference: none`
- `notification_preference: none`
- `accessibility_large_text: false`
- `accessibility_reduce_motion: false`

Typed input must remain available.

Number-word equivalence must remain available for Study grading examples like `five` matching `5`.

## Preference groups

Future grouped preference reads may expose:

Study:

- `preferred_language`
- `study_language`
- `learning_style`
- `study_explanation_depth`
- `study_answer_strictness`
- `study_session_default_mode`

Companion:

- `companion_behavior`
- `companion_tone`
- `companion_memory_scope`

Voice:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`

Calendar:

- `calendar_provider_preference`

Display/accessibility:

- `timezone`
- `locale`
- `notification_preference`
- `accessibility_large_text`
- `accessibility_reduce_motion`

## Calendar boundary

Allowed future calendar provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Disallowed:

- custom local calendar database
- controller-owned calendar event storage

Future behavior:

- `calendar_reads_require_provider_connection: true`
- `calendar_writes_require_explicit_user_request: true`

This preserves the project decision that calendar features must be provider-backed only.

## Privacy and permission contract

Phase 13S requires:

- `no_profile_write_in_this_phase`
- `no_background_personalization_changes`
- `no_sensitive_attribute_inference`
- `preferences_must_not_expose_secrets`
- `read_endpoint_must_not_create_or_update_rows`
- `read_endpoint_must_not_trigger_model_call`
- `read_endpoint_must_not_enqueue_job`
- `read_endpoint_must_not_dispatch_worker`

## Activation gates

Before a live read endpoint can be enabled, later phases must add and pass:

- `requires_profile_preference_schema_migration`
- `requires_profile_preference_read_route`
- `requires_authenticated_user_boundary_smoke`
- `requires_safe_default_response_smoke`
- `requires_no_write_on_read_smoke`
- `requires_no_unknown_field_response_smoke`
- `requires_no_secret_exposure_smoke`
- `requires_profile_settings_ui_patch`
- `requires_study_ui_preference_read_smoke`
- `requires_companion_ui_preference_read_smoke`
- `requires_no_calendar_local_storage_smoke`
- `requires_voice_defaults_regression_smoke`
- `requires_typed_input_regression_smoke`
- `requires_no_login_redirect_regression`
- `requires_live_smoke_before_enable`

## Disabled safety contract

Phase 13S requires:

- no live profile route connection
- no live Study UI connection
- no live Companion UI connection
- no route registration
- no database read
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

After Phase 13S Step 2, expected modified files are:

- `edge_controller.py`
- `docs/phase-13s-disabled-profile-preferences-read-endpoint-contract.md`

The smoke script is added in the next step.
