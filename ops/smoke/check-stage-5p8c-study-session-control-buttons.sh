#!/usr/bin/env bash

stage5p8c_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-8C Study Session Control Buttons Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  for marker in \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" \
    "stage5p8c-study-session-controls" \
    "Study Session Pause" \
    "Study Session Resume" \
    "Study Session Stop" \
    "/api/study/session/command" \
    "Start is intentionally not wired yet"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p8c-study-session-control-buttons.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  for marker in \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "stage5p8a-study-session-status-card" \
    "/api/study/session/status"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css; then
      echo "OK 5P-8A marker $marker"
    else
      echo "FAIL missing 5P-8A marker $marker"
      ok=0
    fi
  done

  grep -nE 'styles.css\?v=|app.js\?v=' frontend/wrapper-ui/index.html || true

  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p8c-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p8c-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p8c-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  curl -fsS "$base/app.js" >/tmp/stage5p8c-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p8c-styles.css || ok=0

  if grep -Fq "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" /tmp/stage5p8c-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" /tmp/stage5p8c-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8C_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8C_SMOKE_FAIL"
  return 1
}

if stage5p8c_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
