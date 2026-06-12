#!/usr/bin/env bash

stage5p5a_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P5A_BASE:-http://127.0.0.1:8787}"
  controller="${STAGE5P5A_CONTROLLER:-http://127.0.0.1:7070}"
  PYBIN="${STAGE5P5A_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"
  tmpdir="/tmp/stage5p5a-command-lifecycle"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-5A Study Session Command Lifecycle Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  for marker in \
    "STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_BEGIN" \
    "_study_execute_lifecycle_command" \
    '@app.post("/api/study/session/command")' \
    '@app.post("/public/study/session/command")' \
    "Intent parsed but command execution is not implemented in Stage 5P-5A" \
    "study_session_start" \
    "study_session_pause" \
    "study_session_resume" \
    "study_session_stop"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== parser direct checks still pass ==="
  "$PYBIN" - <<'PY' || ok=0
import edge_controller as ec
cases = [
    ("Study Session Start", "none", "study_session_start"),
    ("Study Session Pause", "active", "study_session_pause"),
    ("Study Session Resume", "paused", "study_session_resume"),
    ("Study Session Stop", "active", "study_session_stop"),
    ("hello", "none", "general_companion_message"),
]
for message, status, expected in cases:
    parsed = ec._study_parse_deterministic_intent(message, session_status=status)
    assert parsed["intent"] == expected, (message, parsed)
    print("OK", message, "=>", parsed["intent"])
PY

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o "$tmpdir/route.html" -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < "$tmpdir/route.html" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== command endpoint source-level smoke complete ==="
  echo "Runtime command integration will be tested in Stage 5P-5B after controller restart."

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P5A_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P5A_SMOKE_FAIL"
  return 1
}

if stage5p5a_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
