# Stage 5P-1 Study Session + Model Router Contract

## Purpose

Stage 5P-1 defines the shared vocabulary for durable Study sessions, deterministic intent routing, model tiers, and future queue lanes.

This is a contract-only stage. It does not change runtime behavior.

This stage does not add routes, remove routes, modify queue behavior, modify Study behavior, modify Companion behavior, modify auth/header behavior, or add a local calendar database.

Calendar must remain provider-backed only through Google Calendar / Apple Calendar later.

## Canonical study session states

- `none`: no active durable study session exists.
- `active`: a study session is running.
- `paused`: a session exists but should not advance cards.
- `reviewing_answer`: the answer was revealed and the session waits for correct / incorrect / skip.
- `waiting_for_mark`: the user submitted an answer and the system needs a final mark.
- `stopped`: the user intentionally stopped the session.
- `completed`: the review queue is complete.

## Canonical study commands

Session lifecycle:

- `start`
- `pause`
- `resume`
- `stop`
- `status`

Card flow:

- `show_question`
- `read_answer`
- `submit_answer`
- `mark_correct`
- `mark_incorrect`
- `skip`
- `next_card`

## Canonical deterministic intents

Study session intents:

- `study_session_start`
- `study_session_pause`
- `study_session_resume`
- `study_session_stop`
- `study_session_status`

Study card intents:

- `study_show_question`
- `study_read_answer`
- `study_answer_attempt`
- `study_mark_correct`
- `study_mark_incorrect`
- `study_skip`
- `study_next_card`

Companion intents:

- `general_companion_message`
- `companion_support_message`
- `companion_study_help`
- `companion_explain_answer`

Router/system intents:

- `needs_small_model`
- `needs_medium_model`
- `needs_large_model`
- `needs_safety_review`
- `unknown`

## Deterministic parser rules

The first parser should be deterministic, not model-based.

Examples:

- study + session + start/begin/deck/cards -> `study_session_start`
- study + session + pause/hold -> `study_session_pause`
- study + session + resume/continue -> `study_session_resume`
- study + session + stop/end/finish/quit -> `study_session_stop`
- active study session + answer/show answer/read answer -> `study_read_answer`
- active study session + correct/right/got it -> `study_mark_correct`
- active study session + incorrect/wrong/missed it -> `study_mark_incorrect`
- active study session + skip/pass/next -> `study_skip` or `study_next_card`
- active study session + non-command text -> `study_answer_attempt`

## Future backend data contract

The future `study_sessions` table should support:

- `id`
- `user_id`
- `deck_id`
- `status`
- `current_card_id`
- `queue_json`
- `queue_position`
- `started_at`
- `paused_at`
- `ended_at`
- `last_action`
- `last_intent`
- `created_at`
- `updated_at`

Session state is app data, not calendar data.

## Future API contract

Future endpoints:

- `GET /api/study/session/status`
- `POST /api/study/session/start`
- `POST /api/study/session/pause`
- `POST /api/study/session/resume`
- `POST /api/study/session/stop`
- `POST /api/study/session/command`

## Model tier contract

The future router should return a `model_tier`, not a hardcoded model name.

- `small`: deterministic study commands, classification, simple grading, short replies.
- `medium`: tutoring, Companion explanations, answer feedback, study coaching.
- `large`: hard reasoning, coding/debugging, planning, expensive analysis.
- `safety`: safety-sensitive Companion messages and crisis/policy review.

## Queue lane contract

Future `queue_lane` values:

- `study-small`
- `companion-small`
- `companion-medium`
- `reasoning-large`
- `safety`
- `admin-system`

Suggested starting concurrency:

- `study-small`: 2 jobs
- `companion-small`: 1 job
- `companion-medium`: 1 job
- `reasoning-large`: 0 or 1 job
- `safety`: priority lane
- `admin-system`: separate maintenance lane

## Router output contract

Future router output should include:

- `intent`
- `command`
- `session_required`
- `model_tier`
- `queue_lane`
- `max_tokens`
- `reason`

Example intent flow:

User says: read the answer

Expected result during active study session:

- intent: `study_read_answer`
- command: `read_answer`
- model_tier: `small`
- queue_lane: `study-small`

## Keep / migrate / retire

Keep:

- current Study deck/card/review APIs
- current review queue endpoint
- current Companion study grade endpoint
- current queued chat send/poll path
- current public summaries

Migrate:

- old frontend-only Companion study mode state
- answer grading flow
- manual correct/incorrect/skip behavior
- selected deck/current card concepts

Retire later only after tests:

- duplicate Companion legacy headings
- old disabled queued-chat branch skeletons if proven unused
- local reminder/calendar patch code in Study UI if unrelated to provider-backed calendar

## Next stages

1. Stage 5P-2 Backend `study_sessions` table + read-only status endpoint.
2. Stage 5P-3 Start / pause / resume / stop session endpoints.
3. Stage 5P-4 Deterministic study intent parser.
4. Stage 5P-5 `/api/study/session/command`.
5. Stage 5P-6 Model routing policy helper.
6. Stage 5P-7 Queue lanes and concurrency limits.
7. Stage 5P-8 Companion/Study UI session wiring.
