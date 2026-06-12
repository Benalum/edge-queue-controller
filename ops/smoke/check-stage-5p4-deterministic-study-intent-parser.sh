#!/usr/bin/env bash

stage5p4_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P4_BASE:-http://127.0.0.1:8787}"
  PYBIN="${STAGE5P4_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-4 Deterministic Study Intent Parser Smoke ==="

  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  for marker in \
    "STAGE_5P4_STUDY_INTENT_PARSER_BEGIN" \
    "_study_parse_deterministic_intent" \
    "_study_normalize_intent_text" \
    '@app.post("/api/study/intent/parse")' \
    "study_session_start" \
    "study_session_pause" \
    "study_session_resume" \
    "study_session_stop" \
    "study_read_answer" \
    "study_mark_correct" \
    "study_mark_incorrect" \
    "study_skip" \
    "study_answer_attempt" \
    "general_companion_message" \
    "companion-medium" \
    "study-small"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== direct parser unit checks ==="
  "$PYBIN" - <<'PY' || ok=0
import edge_controller as ec

cases = [
    ("Study Session Start", "none", "study_session_start"),
    ("Study Session Pause", "active", "study_session_pause"),
    ("Study Session Resume", "paused", "study_session_resume"),
    ("Study Session Stop", "active", "study_session_stop"),
    ("read the answer", "active", "study_read_answer"),
    ("correct", "active", "study_mark_correct"),
    ("wrong", "active", "study_mark_incorrect"),
    ("skip this", "active", "study_skip"),
    ("mitochondria is the powerhouse", "active", "study_answer_attempt"),
    ("hello there", "none", "general_companion_message"),
]

for message, status, expected in cases:
    parsed = ec._study_parse_deterministic_intent(message, session_status=status)
    actual = parsed.get("intent")
    assert actual == expected, (message, status, expected, parsed)
    print("OK", message, status, "=>", actual)
PY

  echo
  echo "=== wrapper route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p4-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p4-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p4-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P4_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P4_SMOKE_FAIL"
  return 1
}

if stage5p4_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
