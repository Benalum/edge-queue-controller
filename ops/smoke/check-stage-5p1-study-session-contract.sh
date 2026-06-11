#!/usr/bin/env bash

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
