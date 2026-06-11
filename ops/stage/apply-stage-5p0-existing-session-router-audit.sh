#!/usr/bin/env bash

stage5p0_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  echo "=== Stage 5P-0 checkpoint before changes ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== Create Stage 5P-0 audit docs and smoke ==="
  mkdir -p docs ops/smoke ops/stage

  cat > docs/stage-5p0-existing-study-companion-session-router-audit.md <<'MD'
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
MD

  cat > ops/smoke/check-stage-5p0-existing-session-router-audit.sh <<'SMOKE'
#!/usr/bin/env bash

stage5p0_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P0_BASE:-http://127.0.0.1:8787}"
  tmpdir="/tmp/stage5p0-existing-session-router-audit"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-0 Existing Study/Companion Session + Router Audit Smoke ==="
  echo "base=$base"

  echo
  echo "=== git checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== syntax checks ==="
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK wrapper app.js syntax"
  else
    echo "FAIL wrapper app.js syntax"
    ok=0
  fi

  if [ -f frontend/study-ui/app.js ]; then
    if node --check frontend/study-ui/app.js; then
      echo "OK study app.js syntax"
    else
      echo "FAIL study app.js syntax"
      ok=0
    fi
  else
    echo "NOTE frontend/study-ui/app.js not present"
  fi

  if python3 -m py_compile edge_controller.py; then
    echo "OK edge_controller.py syntax"
  else
    echo "FAIL edge_controller.py syntax"
    ok=0
  fi

  echo
  echo "=== required active backend study markers ==="
  required_patterns=(
    "CREATE TABLE IF NOT EXISTS study_decks"
    "CREATE TABLE IF NOT EXISTS study_cards"
    "CREATE TABLE IF NOT EXISTS study_reviews"
    '@app.get("/api/study/decks"'
    '@app.post("/api/study/decks"'
    '@app.get("/api/study/decks/{deck_id}/cards"'
    '@app.post("/api/study/decks/{deck_id}/cards"'
    '@app.post("/api/study/cards/{card_id}/reviews"'
    "review-queue"
    "companion/study/grade"
  )

  for pattern in "${required_patterns[@]}"; do
    if grep -Fq "$pattern" edge_controller.py; then
      echo "OK marker: $pattern"
    else
      echo "FAIL missing marker: $pattern"
      ok=0
    fi
  done

  echo
  echo "=== queued Companion markers ==="
  queued_patterns=(
    "/api/chat/queued"
    "queuedChatSubmit"
    "queuedChatPollJob"
    "queuedChatRenderMessages"
    "STAGE_5O35_COMPANION_UX_BEGIN"
  )

  for pattern in "${queued_patterns[@]}"; do
    if grep -R -Fq "$pattern" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css edge_controller.py; then
      echo "OK marker: $pattern"
    else
      echo "FAIL missing marker: $pattern"
      ok=0
    fi
  done

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
    cat "$tmpdir/public-status.json"
    echo
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
  echo "=== audit inventory excerpt ==="
  {
    echo "# Stage 5P-0 Audit Inventory Excerpt"
    echo
    echo "## Study/session/model/router hits"
    grep -RIn --exclude-dir=.git --exclude-dir=.venv --exclude-dir=venv --exclude-dir=node_modules --exclude-dir=__pycache__ \
      --exclude='*.sqlite3' --exclude='*.db' --exclude='*.log' --exclude='*.bak*' \
      -E "study_session|study session|intent|router|model_tier|ollama|pause|resume|correct|incorrect|skip|read answer|/api/chat/queued|queuedChat|deck|card|review-queue|companion/study/grade" \
      edge_controller.py frontend/wrapper-ui frontend/study-ui docs ops 2>/dev/null | sed -n '1,320p' || true
  } > "$tmpdir/audit-inventory-excerpt.md"

  echo "Wrote $tmpdir/audit-inventory-excerpt.md"
  sed -n '1,120p' "$tmpdir/audit-inventory-excerpt.md"

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P0_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P0_SMOKE_FAIL"
  return 1
}

stage5p0_smoke_main "$@"
return 0 2>/dev/null || true
SMOKE

  chmod +x ops/smoke/check-stage-5p0-existing-session-router-audit.sh

  echo
  echo "=== Add pack creator if present ==="
  if [ -f create_stage5p_inspection_pack.sh ]; then
    chmod +x create_stage5p_inspection_pack.sh
  fi

  echo
  echo "=== Run Stage 5P-0 smoke ==="
  stage_ok=1
  if bash ops/smoke/check-stage-5p0-existing-session-router-audit.sh; then
    echo "OK Stage 5P-0 smoke"
  else
    echo "FAIL Stage 5P-0 smoke"
    stage_ok=0
  fi

  echo
  echo "=== Git diff summary ==="
  git diff -- docs/stage-5p0-existing-study-companion-session-router-audit.md \
              ops/smoke/check-stage-5p0-existing-session-router-audit.sh \
              ops/stage/apply-stage-5p0-existing-session-router-audit.sh \
              create_stage5p_inspection_pack.sh | sed -n '1,260p'

  echo
  echo "=== Commit and tag when checks pass ==="
  if [ "$stage_ok" = "1" ]; then
    git add docs/stage-5p0-existing-study-companion-session-router-audit.md \
            ops/smoke/check-stage-5p0-existing-session-router-audit.sh \
            ops/stage/apply-stage-5p0-existing-session-router-audit.sh

    if [ -f create_stage5p_inspection_pack.sh ]; then
      git add create_stage5p_inspection_pack.sh
    fi

    if git diff --cached --quiet; then
      echo "No staged changes found."
    else
      git commit -m "docs: audit study session router foundation stage 5p0"
    fi

    tag="controller-stage-5p0-existing-session-router-audit-2026-06-11"
    if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
      echo "Tag already exists: $tag"
    else
      git tag "$tag"
      echo "Created tag: $tag"
    fi
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

stage5p0_main "$@"
return 0 2>/dev/null || true
