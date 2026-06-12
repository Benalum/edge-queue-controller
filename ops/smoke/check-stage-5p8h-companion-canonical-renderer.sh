#!/usr/bin/env bash

stage5p8h_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-8H Companion Canonical Renderer Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0

  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== canonical renderer marker checks ==="
  for marker in \
    "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN" \
    "data-stage5p8h-canonical-companion" \
    "stage5p8h-companion-page" \
    "Supportive chat workspace" \
    "queuedChatForm" \
    "queuedChatInput" \
    "queuedChatSendBtn" \
    "queuedChatClearBtn" \
    "queuedChatStatus" \
    "queuedChatMessages" \
    "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_GUARD_BEGIN" \
    "/api/chat/queued"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p8h-companion-canonical-renderer.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== old primary renderer text should be gone from renderQueuedChatPage ==="
  python3 - <<'PY' || ok=0
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()
start = s.find("function renderQueuedChatPage")
end = s.find("async function queuedChatPollJob", start)
body = s[start:end]

bad = [
    "Send a message through the existing laptop-owned queued AI path.",
    "CT101 processes one Ollama job at a time while the UI presents one main Companion surface.",
    "Current model fallback: gemma4:e4b.",
    '<section class="page-card">',
]
missing = [item for item in bad if item in body]
if missing:
    raise SystemExit("Old renderer text still present in renderQueuedChatPage: " + repr(missing))

required = [
    "stage5p8h-companion-page",
    "Supportive chat workspace",
    "queuedChatForm",
    "queuedChatInput",
    "queuedChatMessages",
]
for item in required:
    if item not in body:
        raise SystemExit("Missing canonical renderer item: " + item)

print("OK renderQueuedChatPage is canonical")
PY

  echo
  echo "=== asset cache bust check ==="
  grep -nE 'styles.css\?v=|app.js\?v=' frontend/wrapper-ui/index.html || true

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p8h-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p8h-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p8h-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p8h-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p8h-styles.css || ok=0

  if grep -Fq "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN" /tmp/stage5p8h-app.js; then
    echo "OK live app canonical marker"
  else
    echo "FAIL live app canonical marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P8H_COMPANION_CANONICAL_RENDERER_BEGIN" /tmp/stage5p8h-styles.css; then
    echo "OK live css canonical marker"
  else
    echo "FAIL live css canonical marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8H_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8H_SMOKE_FAIL"
  return 1
}

if stage5p8h_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
