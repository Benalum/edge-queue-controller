# Phase 13X Live Profile Preferences Schema Migration

Phase 13X adds the live SQLite schema migration for `app_user_preferences`.

This phase creates the table only. It does not create preference rows, does not register read/write routes, does not wire frontend settings UI, does not call models, does not enqueue jobs, does not dispatch workers, does not store calendar events, and does not store provider tokens.

## Added source helper

- `_account_init_profile_preferences_table`

The helper is called from:

- `_account_init_tables`

## Created table

- `app_user_preferences`

Ownership:

- owner table: `app_users`
- primary key: `user_id`
- foreign key: `user_id references app_users.id`
- one row per user
- no row creation during migration

## Required columns

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

## Safety requirements

- migration is idempotent
- `app_users` row count remains unchanged
- `app_user_preferences` row count remains 0 after migration
- no auth token columns
- no credit columns
- no provider token columns
- no calendar event storage columns
- no audio blob columns
- no model output columns
- no live profile preference routes
- no frontend preference API wiring

## Calendar boundary

Allowed calendar provider preference values:

- `none`
- `google_calendar`
- `apple_calendar`

The controller must not create a custom local calendar database and must not store calendar events.

## Voice boundary

Voice fields default disabled:

- `voice_enabled`
- `listen_enabled`
- `speak_enabled`
- `auto_listen_enabled`
- `auto_speak_enabled`

Typed input must remain available.

## Exact smoke marker names

The smoke checks also require this exact marker text:

- app_user_preferences row count remains 0
