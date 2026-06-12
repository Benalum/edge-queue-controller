# Stage 5P-11O Cumulative Study Totals

Adds durable cumulative Study totals so detailed history can later be capped by retention policy.

Tables:

- `study_user_totals`
- `study_deck_totals`

Totals include:

- total_cards_reviewed
- total_answered
- total_correct
- total_wrong
- total_skipped
- total_study_seconds

Source of truth for rebuild:

- correct/wrong from `study_reviews`
- skipped from `study_session_events`
- study time from completed/stopped `study_sessions`

Endpoints:

- `POST /system/study/totals/rebuild`
- `POST /api/system/study/totals/rebuild`
- `GET /public/study/totals`
- `GET /api/study/totals`

This stage does not delete detailed rows.
