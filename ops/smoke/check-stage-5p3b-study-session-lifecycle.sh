#!/usr/bin/env bash

stage5p3b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1
  ok=1
  base="${STAGE5P3B_BASE:-http://127.0.0.1:8787}"

  echo "=== Stage 5P-3B Study Session Lifecycle Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  python3 -m py_compile edge_controller.py || ok=0

  for marker in \
    "STAGE_5P3B_STUDY_SESSION_LIFECYCLE_BEGIN" \
    "_study_require_current_session_for_user" \
    "_study_update_session_status" \
    '@app.post("/api/study/session/pause")' \
    '@app.post("/api/study/session/resume")' \
    '@app.post("/api/study/session/stop")' \
    "study_session_pause" \
    "study_session_resume" \
    "study_session_stop"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  for marker in \
    "STAGE_5P2_STUDY_SESSION_STATUS_BEGIN" \
    "STAGE_5P3A_STUDY_SESSION_START_BEGIN" \
    "CREATE TABLE IF NOT EXISTS study_sessions" \
    '@app.get("/api/study/session/status")' \
    '@app.post("/api/study/session/start")' \
    "CREATE TABLE IF NOT EXISTS study_decks" \
    "CREATE TABLE IF NOT EXISTS study_cards" \
    "CREATE TABLE IF NOT EXISTS study_reviews" \
    "/api/chat/queued"
  do
    if grep -R -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js frontend/study-ui/app.js 2>/dev/null; then
      echo "OK existing marker $marker"
    else
      echo "FAIL missing existing marker $marker"
      ok=0
    fi
  done

  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p3b-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p3b-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p3b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P3B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P3B_SMOKE_FAIL"
  return 1
}

stage5p3b_smoke_main "$@"
return 0 2>/dev/null || true
