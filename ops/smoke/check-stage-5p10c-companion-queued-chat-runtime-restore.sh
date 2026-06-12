#!/usr/bin/env bash

stage5p10c_restore_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  controller="http://127.0.0.1:7070"

  echo "=== Stage 5P-10C Companion Queued Chat Runtime Restore Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== env flag presence without values ==="
  for key in LAPTOP_CHAT_QUEUE_ENABLED LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED; do
    if grep -Eq "^${key}=1$" .env; then
      echo "OK $key enabled"
    else
      echo "FAIL $key not enabled in .env"
      ok=0
    fi
  done

  echo
  echo "=== source marker checks ==="
  for marker in \
    "LAPTOP_CHAT_QUEUE_ENABLED" \
    "LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED" \
    "feature_disabled" \
    '@app.post("/api/chat/queued")' \
    '@app.get("/api/chat/queued/{job_id}")' \
    "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN" \
    "queuedChatSubmit" \
    "queuedChatPollJob"
  do
    if grep -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p10c-restore-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p10c-restore-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p10c-restore-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== direct route probe should not be feature_disabled ==="
  probe="$(curl -sS -i -X POST "$controller/api/chat/queued" \
    -H 'Content-Type: application/json' \
    -d '{"message":"stage5p10c restore probe"}' || true)"

  echo "$probe" | sed -n '1,80p'

  if echo "$probe" | grep -q '"error":"feature_disabled"'; then
    echo "FAIL route still feature_disabled"
    ok=0
  else
    echo "OK route no longer feature_disabled"
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P10C_RESTORE_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P10C_RESTORE_SMOKE_FAIL"
  return 1
}

if stage5p10c_restore_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
