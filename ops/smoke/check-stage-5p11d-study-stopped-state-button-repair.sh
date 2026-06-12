#!/usr/bin/env bash

stage5p11d_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11D Study Stopped-State Button Repair Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN" \
    "const canStart = [\"none\", \"stopped\", \"completed\"" \
    "const canPause = activeStates.includes(state)" \
    "const canResume = state === \"paused\"" \
    "const canStop = activeStates.includes(state) || state === \"paused\"" \
    "STAGE_5P11B_STUDY_START_BUTTON_BEGIN" \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p11d-study-stopped-state-button-repair.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== static stopped-state logic check ==="
  python3 - <<'PY' || ok=0
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()
start = s.find("STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN")
end = s.find("STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_END", start)

if start < 0 or end < 0:
    raise SystemExit("repair block missing")

block = s[start:end]
required = [
    '"stopped"',
    '"completed"',
    "if (start) start.disabled = busy || !canStart;",
    "if (refresh) refresh.disabled = busy;",
    "if (pause) pause.disabled = busy || !canPause;",
    "if (resume) resume.disabled = busy || !canResume;",
    "if (stop) stop.disabled = busy || !canStop;",
]
for item in required:
    if item not in block:
        raise SystemExit("missing logic: " + item)

print("OK stopped/completed states can start again")
PY

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11d-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11d-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11d-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11d-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p11d-styles.css || ok=0

  if grep -Fq "STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN" /tmp/stage5p11d-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P11D_STUDY_STOPPED_STATE_BUTTON_REPAIR_BEGIN" /tmp/stage5p11d-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11D_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11D_SMOKE_FAIL"
  return 1
}

if stage5p11d_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
