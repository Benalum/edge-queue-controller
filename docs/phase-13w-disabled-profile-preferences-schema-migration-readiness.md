# Phase 13W Disabled Profile Preferences Schema Migration Readiness

Phase 13W records the readiness contract for the future live `app_user_preferences` schema migration.

This phase is still disabled and inspection-only. It does not create tables, alter tables, read the database, write the database, register routes, modify frontend files, call models, enqueue jobs, dispatch workers, store calendar events, access browser voice APIs, or call Ollama.

## Added helper

- `_stage5p13w_profile_preferences_schema_migration_readiness`

Helper markers:

- `phase_13w_profile_preferences_schema_migration_readiness_helper`
- `disabled_profile_preferences_schema_migration_readiness_only`
- `schema_migration_readiness_only`

## Observed runtime readiness

The prep inspection confirmed:

- database engine: `sqlite3`
- database path constant: `DB_PATH`
- observed database file: `edge_queue.sqlite3`
- account table: `app_users`
- auth session table: `user_sessions`
- account initialization function: `_account_init_tables`
- account column helper: `_account_add_column_if_missing`
- auth user helper: `_auth_current_user_from_request`
- quiet profile stack runner: `ops/smoke/run-stack-quiet.sh profile`

## Future schema contract

Future table:

- `app_user_preferences`

Ownership:

- owner table: `app_users`
- primary key: `user_id`
- foreign key: `user_id references app_users.id`
- one row per user
- avoid expanding `app_users` for every preference

Read/write policy:

- `create_row_on_read: false`
- `read_endpoint_returns_defaults_without_row: true`
- `write_endpoint_may_create_or_update_row_later: true`

Required preference columns:

- `user_id`
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
- `created_at`
- `updated_at`

Boolean columns:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`
- `accessibility_large_text`
- `accessibility_reduce_motion`

Calendar provider values:

- `none`
- `google_calendar`
- `apple_calendar`

## Safe defaults

Future read endpoint defaults remain:

- `preferred_language: en`
- `study_language: preferred_language_or_en`
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

## Storage prohibitions

The future schema must not store:

- auth fields
- credit fields
- provider tokens
- calendar events
- audio blobs
- model outputs
- sensitive attribute inferences

## Migration safety plan

Current phase:

- `current_phase_creates_table: false`
- `current_phase_alters_tables: false`
- `current_phase_reads_database: false`
- `current_phase_writes_database: false`

Future live migration must:

- be idempotent
- preserve existing `app_users`
- not backfill sensitive attributes
- not create preference rows for existing users
- not modify auth or credit columns
- not register routes
- not modify frontend files
- not call models
- not enqueue jobs
- not dispatch workers
- not store calendar events
- not create a custom local calendar database

## Future schema smoke gates

Future live migration must verify:

- migration creates `app_user_preferences`
- required columns exist
- primary key is `user_id`
- foreign key points to `app_users`
- boolean columns are integer-backed
- calendar provider column is preference-only
- no calendar event storage columns exist
- no auth token columns exist
- no credit columns exist
- no audio blob columns exist
- migration is idempotent on second run
- `app_users` row count is unchanged
- no preference rows are created by migration
- health returns 200 after migration
- profile contract stack still passes after migration

## Calendar boundary

Allowed provider preferences:

- `none`
- `google_calendar`
- `apple_calendar`

Calendar policy:

- `custom_local_calendar_database_allowed: false`
- `controller_calendar_event_storage_allowed: false`
- `calendar_provider_preference_only: true`
- `calendar_writes_require_explicit_user_request: true`
- `provider_tokens_must_not_be_visible: true`

## Voice boundary

Voice policy:

- `voice_defaults_disabled: true`
- `listen_default_false: true`
- `speak_default_false: true`
- `auto_listen_default_false: true`
- `auto_speak_default_false: true`
- `typed_input_must_remain_available: true`
- `browser_microphone_requires_explicit_user_action: true`
- `browser_speech_output_requires_explicit_user_action: true`

## Disabled safety

Phase 13W requires:

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

## Exact smoke marker names

The smoke checks also require these exact marker names from the helper contract:

- `future_migration_must_be_idempotent`
- `verify_migration_creates_app_user_preferences`
- `verify_app_users_row_count_unchanged`
