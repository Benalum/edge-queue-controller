#!/usr/bin/env bash

stage5p7a_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1

  echo "=== Stage 5P-7A Controller Restart Helper Smoke ==="

  echo
  echo "=== syntax checks ==="
  bash -n ops/dev/restart-controller-7070.sh || ok=0
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== helper marker checks ==="
  for marker in \
    "restart_controller_7070_main" \
    "RESTART_CONTROLLER_7070_OK" \
    "controller-7070-dev.log" \
    "api/study/session/status" \
    "Port 7070 is still busy" \
    "return 0 2>/dev/null || true"
  do
    if grep -Fq "$marker" ops/dev/restart-controller-7070.sh; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== run helper ==="
  if bash ops/dev/restart-controller-7070.sh | tee /tmp/stage5p7a-restart-helper.log; then
    if grep -q "RESTART_CONTROLLER_7070_OK" /tmp/stage5p7a-restart-helper.log; then
      echo "OK helper restart"
    else
      echo "FAIL helper did not print success marker"
      ok=0
    fi
  else
    echo "FAIL helper restart command"
    ok=0
  fi

  echo
  echo "=== listener check ==="
  if ss -ltnp | grep -q ':7070'; then
    ss -ltnp | grep ':7070'
    echo "OK controller listener present"
  else
    echo "FAIL controller listener missing"
    ok=0
  fi

  echo
  echo "=== route smoke through wrapper ==="
  if curl -fsS http://127.0.0.1:8787/api/system/public-status >/tmp/stage5p7a-public-status.json; then
    echo "OK wrapper public-status"
  else
    echo "FAIL wrapper public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p7a-route.html -w "%{http_code}" "http://127.0.0.1:8787$route" || true)"
    bytes="$(wc -c < /tmp/stage5p7a-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P7A_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P7A_SMOKE_FAIL"
  return 1
}

if stage5p7a_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
