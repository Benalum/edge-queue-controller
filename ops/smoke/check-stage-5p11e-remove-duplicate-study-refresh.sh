#!/usr/bin/env bash

stage5p11e_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11E Remove Duplicate Study Refresh Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11E_REMOVE_DUPLICATE_STUDY_REFRESH_BEGIN" \
    "data-stage5p8a-refresh" \
    "data-stage5p8c-command=\"start\"" \
    "data-stage5p8c-command=\"pause\"" \
    "data-stage5p8c-command=\"resume\"" \
    "data-stage5p8c-command=\"stop\"" \
    "STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js docs/stage-5p11e-remove-duplicate-study-refresh.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== ensure lower duplicate Refresh command is gone ==="
  if grep -Fq 'data-stage5p8c-command="refresh"' frontend/wrapper-ui/app.js; then
    echo "FAIL lower Refresh command still present"
    ok=0
  else
    echo "OK lower Refresh command removed"
  fi

  echo
  echo "=== ensure top Refresh remains ==="
  if grep -Fq 'data-stage5p8a-refresh' frontend/wrapper-ui/app.js; then
    echo "OK top status Refresh remains"
  else
    echo "FAIL top status Refresh missing"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11e-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11e-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11e-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker check ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11e-app.js || ok=0

  if grep -Fq "STAGE_5P11E_REMOVE_DUPLICATE_STUDY_REFRESH_BEGIN" /tmp/stage5p11e-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11E_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11E_SMOKE_FAIL"
  return 1
}

if stage5p11e_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
