#!/usr/bin/env bash

stage5p6b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P6B_BASE:-http://127.0.0.1:8787}"
  PYBIN="${STAGE5P6B_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-6B Study Session Mark Card Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P6B_STUDY_MARK_CARD_BEGIN" \
    "_study_mark_current_card_for_session" \
    "_study_session_queue_items" \
    "study_mark_correct" \
    "study_mark_incorrect" \
    "mark_correct" \
    "mark_incorrect" \
    "INSERT INTO study_reviews" \
    "Cannot mark card while study session is paused" \
    "STAGE_5P6A_STUDY_READ_ANSWER_BEGIN" \
    "STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_BEGIN"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== parser direct checks ==="
  "$PYBIN" - <<'PY' || ok=0
import edge_controller as ec

cases = [
    ("correct", "reviewing_answer", "study_mark_correct", "mark_correct"),
    ("wrong", "reviewing_answer", "study_mark_incorrect", "mark_incorrect"),
    ("got it", "active", "study_mark_correct", "mark_correct"),
    ("missed it", "active", "study_mark_incorrect", "mark_incorrect"),
]

for message, status, expected_intent, expected_command in cases:
    parsed = ec._study_parse_deterministic_intent(message, session_status=status)
    assert parsed["intent"] == expected_intent, (message, parsed)
    assert parsed["command"] == expected_command, (message, parsed)
    print("OK", message, status, "=>", parsed["intent"], parsed["command"])
PY

  echo
  echo "=== wrapper route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p6b-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p6b-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p6b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  if [ "$ok" = "1" ]; then
    echo "STAGE_5P6B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P6B_SMOKE_FAIL"
  return 1
}

if stage5p6b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
