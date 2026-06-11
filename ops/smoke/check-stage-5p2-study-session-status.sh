#!/usr/bin/env bash

stage5p2_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1
  ok=1
  base="${STAGE5P2_BASE:-http://127.0.0.1:8787}"

  echo "=== Stage 5P-2 Study Session Status Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  python3 -m py_compile edge_controller.py || ok=0

  for marker in \
    "STAGE_5P2_STUDY_SESSION_STATUS_BEGIN" \
    "CREATE TABLE IF NOT EXISTS study_sessions" \
    "idx_study_sessions_user_status" \
    "_study_init_session_tables" \
    "_study_get_current_session_for_user" \
    "_study_session_row_to_public" \
    '@app.get("/api/study/session/status")' \
    '@app.get("/public/study/session/status")'
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  for marker in \
    "CREATE TABLE IF NOT EXISTS study_decks" \
    "CREATE TABLE IF NOT EXISTS study_cards" \
    "CREATE TABLE IF NOT EXISTS study_reviews" \
    "review-queue" \
    "companion/study/grade" \
    "/api/chat/queued"
  do
    if grep -R -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js frontend/study-ui/app.js 2>/dev/null; then
      echo "OK existing marker $marker"
    else
      echo "FAIL missing existing marker $marker"
      ok=0
    fi
  done

  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p2-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p2-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p2-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P2_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P2_SMOKE_FAIL"
  return 1
}

stage5p2_smoke_main "$@"
return 0 2>/dev/null || true
