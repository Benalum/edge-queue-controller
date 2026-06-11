# Stage 5P-0 Existing Study / Companion Session + Router Audit

## Purpose

Stage 5P-0 audits existing Study, Companion, queue, session-like, and model-routing code before adding the new durable Study Session + Model Router foundation.

This is intentionally a documentation and smoke-test stage only.

## Runtime behavior

No runtime behavior is changed.

This stage does not:
- add backend routes
- remove backend routes
- modify queue behavior
- modify Companion behavior
- modify Study behavior
- modify auth/header behavior
- add a local calendar database

## Current good checkpoint before this stage

- Stage 5O-36 Companion browser/render regression smoke
- Tag: `controller-stage-5o36-companion-browser-render-regression-smoke-2026-06-11`

## Existing pieces to keep

The current backend already has useful Study foundations:

- `study_decks`
- `study_cards`
- `study_reviews`
- `/api/study/decks`
- `/api/study/decks/{deck_id}/cards`
- `/api/study/cards/{card_id}/reviews`
- `/api/study/progress`
- `/api/study/decks/{deck_id}/card-stats`
- `/api/study/decks/{deck_id}/review-queue`
- `/api/companion/study/grade`

These should be kept and reused.

## Existing pieces to migrate

The Study frontend already appears to have a Companion-style study flow with concepts like:

- selected deck
- review queue
- current card
- answer submission
- auto-grading
- manual correct / incorrect confirmation
- next-card behavior

These ideas are useful, but the state is mostly frontend-memory oriented. The new structure should migrate the useful workflow into durable per-user session state.

## Existing pieces to audit before deleting

Some code appears old, experimental, or possibly obsolete:

- disabled queued-chat branch skeletons from previous stages
- duplicate Companion page headings created by wrapping old UI in the new Stage 5O-35 shell
- older Study UI Companion/local reminder/calendar patch code

Do not delete these blindly. Retire them only after a smoke proves the active flows are not using them.

## New structure needed

The next functional track should create:

### Durable study session state

A backend-owned state model such as:

- `id`
- `user_id`
- `deck_id`
- `status`
- `current_card_id`
- `queue_position`
- `started_at`
- `paused_at`
- `ended_at`
- `last_action`
- `last_intent`
- `created_at`
- `updated_at`

Likely statuses:

- `none`
- `active`
- `paused`
- `reviewing_answer`
- `waiting_for_mark`
- `stopped`
- `completed`

### Deterministic study intent router

Start with deterministic rules before using a model:

- `study_session_start`
- `study_session_pause`
- `study_session_resume`
- `study_session_stop`
- `study_read_answer`
- `study_mark_correct`
- `study_mark_incorrect`
- `study_skip`
- `study_answer_attempt`
- `general_companion_message`

### Model routing contract

Add a model-router contract later:

- `small` for deterministic study commands, short answers, simple grading
- `medium` for tutoring, Companion replies, explanations
- `large` for deep reasoning, planning, debugging, complex safety-sensitive cases

### Queue lane contract

Add queue lanes later:

- `study-small`
- `companion-medium`
- `reasoning-large`
- `safety`
- `admin-system`

The system should protect resources by avoiding large models unless the intent requires them.

## Recommended next stages

1. Stage 5P-1 Study session state contract
2. Stage 5P-2 Backend `study_sessions` table + read-only status endpoint
3. Stage 5P-3 Start / pause / resume / stop session commands
4. Stage 5P-4 Deterministic intent router
5. Stage 5P-5 Model routing policy
6. Stage 5P-6 Queue lanes and concurrency limits
7. Stage 5P-7 Companion/Study UI wiring to durable sessions

## Notes

Calendar must remain provider-backed only. Do not add a local calendar database.
