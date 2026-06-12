#!/usr/bin/env bash

stage5p8a_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P8A_BASE:-http://127.0.0.1:8787}"

  echo "=== Stage 5P-8A Study Session Status Card Smoke ==="

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
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "stage5p8a-study-session-status-card" \
    "/api/study/session/status" \
    "Command buttons come later" \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_END"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== asset reference checks ==="
  grep -nE 'styles.css\?v=|app.js\?v=' frontend/wrapper-ui/index.html || true

  if grep -Eq 'styles.css\?v=[0-9]+' frontend/wrapper-ui/index.html; then
    echo "OK styles cache bust"
  else
    echo "FAIL styles cache bust"
    ok=0
  fi

  if grep -Eq 'app.js\?v=[0-9]+' frontend/wrapper-ui/index.html; then
    echo "OK app cache bust"
  else
    echo "FAIL app cache bust"
    ok=0
  fi

  echo
  echo "=== wrapper route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p8a-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p8a-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p8a-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p8a-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p8a-styles.css || ok=0

  if grep -Fq "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" /tmp/stage5p8a-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" /tmp/stage5p8a-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8A_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8A_SMOKE_FAIL"
  return 1
}

if stage5p8a_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
