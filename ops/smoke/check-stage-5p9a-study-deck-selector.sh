#!/usr/bin/env bash

stage5p9a_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-9A Study Deck Selector Smoke ==="

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
    "STAGE_5P9A_STUDY_DECK_SELECTOR_BEGIN" \
    "stage5p9a-study-deck-selector" \
    "stage5p9aSelectedStudyDeckId" \
    "/api/study/decks" \
    "Start is not wired yet" \
    "STAGE_5P8A_STUDY_SESSION_STATUS_CARD_BEGIN" \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" \
    "STAGE_5P8F_REFRESH_LOOP_GUARD_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p9a-study-deck-selector.md; then
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
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p9a-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p9a-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p9a-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p9a-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p9a-styles.css || ok=0

  if grep -Fq "STAGE_5P9A_STUDY_DECK_SELECTOR_BEGIN" /tmp/stage5p9a-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P9A_STUDY_DECK_SELECTOR_BEGIN" /tmp/stage5p9a-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P9A_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P9A_SMOKE_FAIL"
  return 1
}

if stage5p9a_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
