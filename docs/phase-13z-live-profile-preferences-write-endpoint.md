# Phase 13Z Live Profile Preferences Write Endpoint

Phase 13Z adds the live authenticated write endpoint for profile preferences:

- `PATCH /api/profile/preferences`

The endpoint writes only to:

- `app_user_preferences`

It does not write to `app_users`, auth fields, credit fields, provider tokens, calendar events, audio blobs, model outputs, queue state, or worker state.

## Safety rules

This phase must:

- authenticate the user
- accept only allowlisted preference fields
- reject unknown fields
- reject forbidden fields
- validate enum fields
- validate boolean fields
- upsert one row per user
- preserve `created_at`
- update `updated_at`
- return the merged preference object
- keep typed input available
- avoid custom local calendar databases
- avoid controller-owned calendar event storage

## Forbidden fields

Forbidden write fields include:

- `id`
- `user_id`
- `email`
- `password`
- `password_hash`
- `role`
- `plan`
- `credits`
- `credit_balance`
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

## Calendar boundary

Allowed calendar provider preference values remain:

- `none`
- `google_calendar`
- `apple_calendar`

The controller must not create a custom local calendar database and must not store calendar events.

## Voice boundary

Voice settings remain explicit preferences and do not activate microphone or speech APIs by themselves.
