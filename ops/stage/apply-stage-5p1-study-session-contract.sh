#!/usr/bin/env bash

stage5p1_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  echo "=== Stage 5P-1 checkpoint before changes ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  mkdir -p docs ops/smoke ops/stage

  echo
  echo "=== Write Stage 5P-1 contract and smoke with Python ==="
  python3 - <<'PY'
from pathlib import Path

doc = """# Stage 5P-1 Study Session + Model Router Contract

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
"""

smoke = """#!/usr/bin/env bash

stage5p1_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P1_BASE:-http://127.0.0.1:8787}"
  doc="docs/stage-5p1-study-session-model-router-contract.md"
  tmpdir="/tmp/stage5p1-study-session-contract"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-1 Study Session + Model Router Contract Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0

  if [ -f frontend/study-ui/app.js ]; then
    node --check frontend/study-ui/app.js || ok=0
  fi

  python3 -m py_compile edge_controller.py || ok=0

  echo
  echo "=== contract required terms ==="
  terms=(
    "study_session_start"
    "study_session_pause"
    "study_session_resume"
    "study_session_stop"
    "study_read_answer"
    "study_mark_correct"
    "study_mark_incorrect"
    "study_skip"
    "study_answer_attempt"
    "general_companion_message"
    "needs_safety_review"
    "study_sessions"
    "GET /api/study/session/status"
    "POST /api/study/session/start"
    "POST /api/study/session/pause"
    "POST /api/study/session/resume"
    "POST /api/study/session/stop"
    "POST /api/study/session/command"
    "model_tier"
    "queue_lane"
    "study-small"
    "companion-medium"
    "reasoning-large"
    "safety"
  )

  for term in "${terms[@]}"; do
    if grep -Fq "$term" "$doc"; then
      echo "OK $term"
    else
      echo "FAIL missing $term"
      ok=0
    fi
  done

  echo
  echo "=== state checks ==="
  for state in none active paused reviewing_answer waiting_for_mark stopped completed; do
    if grep -Fq "\`$state\`" "$doc"; then
      echo "OK state $state"
    else
      echo "FAIL missing state $state"
      ok=0
    fi
  done

  echo
  echo "=== existing runtime markers ==="
  markers=(
    "CREATE TABLE IF NOT EXISTS study_decks"
    "CREATE TABLE IF NOT EXISTS study_cards"
    "CREATE TABLE IF NOT EXISTS study_reviews"
    "review-queue"
    "companion/study/grade"
    "/api/chat/queued"
    "queuedChatSubmit"
    "queuedChatPollJob"
  )

  for marker in "${markers[@]}"; do
    if grep -R -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js frontend/study-ui/app.js 2>/dev/null; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    outfile="$tmpdir/${route////_}.html"
    code="$(curl -sS -L -o "$outfile" -w "%{http_code}" "$base$route" 2>> "$tmpdir/routes.err" || true)"
    bytes="$(wc -c < "$outfile" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P1_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P1_SMOKE_FAIL"
  return 1
}

stage5p1_smoke_main "$@"
return 0 2>/dev/null || true
"""

Path("docs/stage-5p1-study-session-model-router-contract.md").write_text(doc)
Path("ops/smoke/check-stage-5p1-study-session-contract.sh").write_text(smoke)
PY

  chmod +x ops/smoke/check-stage-5p1-study-session-contract.sh

  echo
  echo "=== Run Stage 5P-1 smoke ==="
  stage_ok=1
  if bash ops/smoke/check-stage-5p1-study-session-contract.sh; then
    echo "OK Stage 5P-1 smoke"
  else
    echo "FAIL Stage 5P-1 smoke"
    stage_ok=0
  fi

  echo
  echo "=== Commit and tag when checks pass ==="
  if [ "$stage_ok" = "1" ]; then
    git add docs/stage-5p1-study-session-model-router-contract.md \
            ops/smoke/check-stage-5p1-study-session-contract.sh \
            ops/stage/apply-stage-5p1-study-session-contract.sh

    git commit -m "docs: define study session router contract stage 5p1"

    tag="controller-stage-5p1-study-session-router-contract-2026-06-11"
    git tag "$tag"
    echo "Created tag: $tag"
  else
    echo "Checks failed. No commit/tag attempted."
  fi

  echo
  echo "=== Final checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  return 0
}

stage5p1_main "$@"
return 0 2>/dev/null || true
