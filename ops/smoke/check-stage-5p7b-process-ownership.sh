#!/usr/bin/env bash

stage5p7b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1

  echo "=== Stage 5P-7B Controller / Wrapper Process Ownership Smoke ==="

  echo
  echo "=== syntax checks ==="
  bash -n ops/dev/restart-controller-7070.sh || ok=0
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== listener ownership ==="
  controller_count="$(ss -ltnp | grep -E ':7070' | wc -l | tr -d ' ')"
  wrapper_count="$(ss -ltnp | grep -E ':8787' | wc -l | tr -d ' ')"

  echo "controller_count=$controller_count"
  ss -ltnp | grep -E ':7070' || true

  echo "wrapper_count=$wrapper_count"
  ss -ltnp | grep -E ':8787' || true

  if [ "$controller_count" = "1" ]; then
    echo "OK exactly one controller listener on 7070"
  else
    echo "FAIL expected exactly one controller listener on 7070"
    ok=0
  fi

  if [ "$wrapper_count" = "1" ]; then
    echo "OK exactly one wrapper listener on 8787"
  else
    echo "FAIL expected exactly one wrapper listener on 8787"
    ok=0
  fi

  echo
  echo "=== process command inspection ==="
  controller_pid="$(ss -ltnp | awk '/:7070/ {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -1)"
  wrapper_pid="$(ss -ltnp | awk '/:8787/ {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -1)"

  echo "controller_pid=$controller_pid"
  [ -z "$controller_pid" ] || ps -fp "$controller_pid" || true

  echo "wrapper_pid=$wrapper_pid"
  [ -z "$wrapper_pid" ] || ps -fp "$wrapper_pid" || true

  if [ -n "$controller_pid" ] && tr '\0' ' ' < "/proc/$controller_pid/cmdline" | grep -Fq "edge_controller:app"; then
    echo "OK controller process is uvicorn edge_controller:app"
  else
    echo "FAIL controller process command does not look like edge_controller:app"
    ok=0
  fi

  if [ -n "$wrapper_pid" ] && tr '\0' ' ' < "/proc/$wrapper_pid/cmdline" | grep -Fq "frontend/wrapper-ui/dev_server.py"; then
    echo "OK wrapper process is dev_server.py"
  else
    echo "FAIL wrapper process command does not look like dev_server.py"
    ok=0
  fi

  echo
  echo "=== hidden owner audit ==="
  user_units="$(systemctl --user list-units --all 2>/dev/null | grep -Ei 'edge|controller|wrapper|queue' || true)"
  user_timers="$(systemctl --user list-timers --all 2>/dev/null | grep -Ei 'edge|controller|wrapper|queue|remediation' || true)"
  cron_hits="$(crontab -l 2>/dev/null | grep -Ei 'edge|controller|wrapper|queue|uvicorn' || true)"

  if [ -z "$user_units" ]; then
    echo "OK no matching user systemd units currently own controller/wrapper"
  else
    echo "INFO matching user units:"
    echo "$user_units"
  fi

  if [ -z "$user_timers" ]; then
    echo "OK no matching user timers currently own controller/wrapper"
  else
    echo "INFO matching user timers:"
    echo "$user_timers"
  fi

  if [ -z "$cron_hits" ]; then
    echo "OK no matching user crontab owner found"
  else
    echo "INFO matching crontab entries:"
    echo "$cron_hits"
  fi

  echo
  echo "=== endpoint checks ==="
  code="$(curl -sS -o /tmp/stage5p7b-controller-status.json -w "%{http_code}" http://127.0.0.1:7070/api/study/session/status 2>/tmp/stage5p7b-controller.err || true)"
  if [ "$code" = "401" ] || [ "$code" = "200" ]; then
    echo "OK controller status endpoint code=$code"
  else
    echo "FAIL controller status endpoint code=$code"
    ok=0
  fi

  if curl -fsS http://127.0.0.1:8787/api/system/public-status >/tmp/stage5p7b-wrapper-status.json; then
    echo "OK wrapper public-status"
  else
    echo "FAIL wrapper public-status"
    ok=0
  fi

  echo
  echo "=== route smoke through wrapper ==="
  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p7b-route.html -w "%{http_code}" "http://127.0.0.1:8787$route" || true)"
    bytes="$(wc -c < /tmp/stage5p7b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P7B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P7B_SMOKE_FAIL"
  return 1
}

if stage5p7b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
