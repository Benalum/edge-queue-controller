#!/usr/bin/env bash

stage5p11a_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11A Companion Study Phrase Guide Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11A_COMPANION_STUDY_PHRASE_GUIDE_BEGIN" \
    "stage5p11a-study-phrase-guide" \
    "Study phrases" \
    "Study session start" \
    "Study session pause" \
    "Study session resume" \
    "Study session stop" \
    "Read the answer" \
    "Correct" \
    "wrong" \
    "skip" \
    "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p11a-companion-study-phrase-guide.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== ensure old placeholder is removed ==="
  if grep -Fq "Future toggle placeholder. No Study data is connected here yet." frontend/wrapper-ui/app.js; then
    echo "FAIL old Study context placeholder still present"
    ok=0
  else
    echo "OK old Study context placeholder removed"
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11a-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11a-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11a-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11a-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p11a-styles.css || ok=0

  if grep -Fq "STAGE_5P11A_COMPANION_STUDY_PHRASE_GUIDE_BEGIN" /tmp/stage5p11a-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P11A_COMPANION_STUDY_PHRASE_GUIDE_BEGIN" /tmp/stage5p11a-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11A_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11A_SMOKE_FAIL"
  return 1
}

if stage5p11a_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
