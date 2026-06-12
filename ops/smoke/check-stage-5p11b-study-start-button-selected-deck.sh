#!/usr/bin/env bash

stage5p11b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11B Study Start Button Selected Deck Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11B_STUDY_START_BUTTON_BEGIN" \
    "STAGE_5P11B_STUDY_START_BUTTON_LOGIC_BEGIN" \
    "data-stage5p8c-command=\"start\"" \
    "/api/study/session/start" \
    "stage5p9aSelectedStudyDeckId" \
    "Choose a deck below, then press Start." \
    "Start uses the selected deck id to create a durable Study session." \
    "STAGE_5P9A_STUDY_DECK_SELECTOR_BEGIN" \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p11b-study-start-button-selected-deck.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== old disabled-start copy should be gone ==="
  for old_marker in \
    "Start is intentionally not wired yet" \
    "future Start button" \
    "Start is not wired yet"
  do
    if grep -Fq "$old_marker" frontend/wrapper-ui/app.js; then
      echo "FAIL old marker still present $old_marker"
      ok=0
    else
      echo "OK old marker removed $old_marker"
    fi
  done

  echo
  echo "=== live API route sanity ==="
  # Endpoint should exist and require auth / validate request, not 404.
  code="$(curl -sS -o /tmp/stage5p11b-start-noauth.json -w "%{http_code}" \
    -X POST "$base/api/study/session/start" \
    -H "Content-Type: application/json" \
    --data '{"deck_id":"1"}' || true)"
  body="$(cat /tmp/stage5p11b-start-noauth.json 2>/dev/null || true)"
  echo "start_noauth_code=$code"
  echo "start_noauth_body=${body:0:240}"
  if [ "$code" = "404" ]; then
    echo "FAIL start endpoint returned 404"
    ok=0
  else
    echo "OK start endpoint exists"
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11b-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11b-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11b-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p11b-styles.css || ok=0

  if grep -Fq "STAGE_5P11B_STUDY_START_BUTTON_BEGIN" /tmp/stage5p11b-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P11B_STUDY_START_BUTTON_BEGIN" /tmp/stage5p11b-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11B_SMOKE_FAIL"
  return 1
}

if stage5p11b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
