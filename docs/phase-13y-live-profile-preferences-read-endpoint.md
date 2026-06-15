# Phase 13Y Live Profile Preferences Read Endpoint

Phase 13Y adds the live authenticated read endpoint for profile preferences:

- `GET /api/profile/preferences`

The endpoint reads from:

- `app_users`
- `app_user_preferences`

It returns safe defaults when a user does not yet have a row in `app_user_preferences`.

## Safety rules

This phase must not:

- create a missing `app_user_preferences` row on read
- write to `app_user_preferences`
- update `app_users`
- register write routes
- modify frontend files
- call models
- enqueue jobs
- dispatch workers
- store calendar events
- store provider tokens
- access browser microphone APIs
- access browser speech APIs
- call Ollama directly

## Read behavior

When `app_user_preferences` has no row for the authenticated user, the endpoint returns safe defaults:

- `preferred_language: en`
- `study_language: en`
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

## Calendar boundary

Allowed calendar provider preference values remain:

- `none`
- `google_calendar`
- `apple_calendar`

The controller must not create a custom local calendar database and must not store calendar events.

## Voice boundary

Voice settings default disabled, and typed input must remain available.
