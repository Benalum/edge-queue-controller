#!/usr/bin/env bash

stage5p8b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1
  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-8B Study Deck / Session UI Audit Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  for marker in \
    "Stage 5P-8B Study Deck / Session UI Audit" \
    "Start requires a reliable deck id source" \
    "Pause / Resume / Stop can be added first"
  do
    if grep -Fq "$marker" docs/stage-5p8b-study-deck-session-ui-audit.md docs/stage-5p8b-study-deck-session-ui-audit-report.txt; then
      echo "OK audit marker $marker"
    else
      echo "FAIL missing audit marker $marker"
      ok=0
    fi
  done

  for marker in \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "stage5p8a-study-session-status-card" \
    "/api/study/session/status"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css; then
      echo "OK Stage 5P-8A marker $marker"
    else
      echo "FAIL missing Stage 5P-8A marker $marker"
      ok=0
    fi
  done

  for marker in \
    '@app.post("/api/study/session/command")' \
    "study_session_start" \
    "study_mark_correct" \
    "study_skip" \
    "study_next_card"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK backend marker $marker"
    else
      echo "FAIL missing backend marker $marker"
      ok=0
    fi
  done

  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p8b-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p8b-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p8b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8B_SMOKE_FAIL"
  return 1
}

if stage5p8b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
