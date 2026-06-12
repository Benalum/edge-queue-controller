#!/usr/bin/env bash

restart_controller_7070_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  mkdir -p logs

  echo "=== restart controller on :7070 ==="

  current_pid="$(ss -ltnp 2>/dev/null | awk '/:7070/ {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -1 || true)"

  if [ -n "$current_pid" ]; then
    echo "Stopping existing controller pid=$current_pid"

    kill "$current_pid" 2>/dev/null || true

    for i in $(seq 1 30); do
      if ss -ltnp 2>/dev/null | grep -q ':7070'; then
        sleep 1
      else
        echo "Port 7070 is free"
        break
      fi
    done

    if ss -ltnp 2>/dev/null | grep -q ':7070'; then
      echo "Port 7070 still busy after graceful stop; trying one force stop"
      kill -9 "$current_pid" 2>/dev/null || true

      for i in $(seq 1 10); do
        if ss -ltnp 2>/dev/null | grep -q ':7070'; then
          sleep 1
        else
          echo "Port 7070 is free after force stop"
          break
        fi
      done
    fi
  else
    echo "No existing controller listener found on :7070"
  fi

  if ss -ltnp 2>/dev/null | grep -q ':7070'; then
    echo "ERROR: Port 7070 is still busy. Not starting duplicate controller."
    ss -ltnp | grep ':7070' || true
    return 1
  fi

  PY="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  if [ ! -x "$PY" ]; then
    PY="python3"
  fi

  echo "Starting controller with: $PY -m uvicorn edge_controller:app --host 0.0.0.0 --port 7070"

  nohup bash -lc '
cd "$HOME/Desktop/edge-queue-controller"
set -a
[ -f .env ] && . ./.env
set +a

PY="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
[ -x "$PY" ] || PY=python3

exec "$PY" -m uvicorn edge_controller:app --host 0.0.0.0 --port 7070
' > logs/controller-7070-dev.log 2>&1 &

  new_pid="$!"
  echo "started_pid=$new_pid"

  ready=0
  for i in $(seq 1 30); do
    code="$(curl -sS -o /tmp/controller-7070-restart-status.json -w "%{http_code}" http://127.0.0.1:7070/api/study/session/status 2>/tmp/controller-7070-restart-curl.err || true)"
    if [ "$code" = "401" ] || [ "$code" = "200" ]; then
      echo "Controller ready; status endpoint code=$code"
      ready=1
      break
    fi

    if ! kill -0 "$new_pid" 2>/dev/null; then
      echo "Controller process exited early. Recent log:"
      tail -80 logs/controller-7070-dev.log || true
      return 1
    fi

    sleep 1
  done

  if [ "$ready" != "1" ]; then
    echo "Controller did not become ready. Recent log:"
    tail -80 logs/controller-7070-dev.log || true
    return 1
  fi

  echo "RESTART_CONTROLLER_7070_OK"
  return 0
}

restart_controller_7070_main "$@"
return 0 2>/dev/null || true
