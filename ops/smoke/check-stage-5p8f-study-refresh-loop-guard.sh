#!/usr/bin/env bash

stage5p8f_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-8F Study Refresh Loop Guard Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== marker checks ==="
  for marker in \
    "STAGE_5P8F_REFRESH_LOOP_GUARD_BEGIN" \
    "stage5p8aStatusLoaded" \
    "STAGE_5P8F_CONTROL_INTERVAL_GUARD_BEGIN" \
    "10000" \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN"
  do
    if grep -Fq "$marker" frontend/wrapper-ui/app.js; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== asset cache bust check ==="
  grep -nE 'styles.css\?v=|app.js\?v=' frontend/wrapper-ui/index.html || true

  echo
  echo "=== wrapper route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p8f-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p8f-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p8f-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker check ==="
  curl -fsS "$base/app.js" >/tmp/stage5p8f-app.js || ok=0

  if grep -Fq "STAGE_5P8F_REFRESH_LOOP_GUARD_BEGIN" /tmp/stage5p8f-app.js; then
    echo "OK live app refresh-loop marker"
  else
    echo "FAIL live app refresh-loop marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8F_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8F_SMOKE_FAIL"
  return 1
}

if stage5p8f_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
