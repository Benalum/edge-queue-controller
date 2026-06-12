# Stage 5P-11L Study Session Events and Summary Metrics

Adds durable `study_session_events`.

Why this is needed:

- `study_reviews` tracks correct/wrong reviews.
- Skip previously advanced the Study session but did not create per-card durable history.
- A clean Session Summary needs correct, wrong, and skipped counts.

This stage adds event tracking for:

- start
- read_answer
- pause
- resume
- stop
- mark_correct
- mark_incorrect
- skip

The session status payload now includes a `summary` object:

- cards_total
- cards_reviewed
- correct_count
- wrong_count
- skipped_count
- answered_count
- accuracy
- elapsed_seconds
- started_at
- ended_at

This prepares the Study tab to become a clean summary/dashboard later.
