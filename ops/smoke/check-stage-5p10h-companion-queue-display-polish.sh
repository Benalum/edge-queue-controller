#!/usr/bin/env bash

stage5p10h_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-10H Companion Queue Display Polish Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_BEGIN" \
    "queuedChatQueueSummary" \
    "Done" \
    "Running" \
    "Failed" \
    "Cancelled" \
    "STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_BEGIN" \
    "STAGE_5P10F_REAL_USER_QUEUE_STATUS_BRIDGE_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js edge_controller.py docs/stage-5p10h-companion-queue-display-polish.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== verify raw complete/running display strings replaced in polish block ==="
  python3 - <<'PY' || ok=0
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()
start = s.find("STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_BEGIN")
end = s.find("STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_END", start)

if start < 0 or end < 0:
    raise SystemExit("polish block missing")

block = s[start:end]
required = ['"Done"', '"Running"', '"Failed"', '"Cancelled"']
for item in required:
    if item not in block:
        raise SystemExit(f"missing {item}")

bad = ['"complete"', '"running"', '"failed"', '"cancelled"']
for item in bad:
    if f'queuedChatQueueSummary", {item}' in block:
        raise SystemExit(f"raw display still present {item}")

print("OK polished display strings")
PY

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p10h-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p10h-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p10h-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker check ==="
  curl -fsS "$base/app.js" >/tmp/stage5p10h-app.js || ok=0

  if grep -Fq "STAGE_5P10H_COMPANION_QUEUE_DISPLAY_POLISH_BEGIN" /tmp/stage5p10h-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P10H_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P10H_SMOKE_FAIL"
  return 1
}

if stage5p10h_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
