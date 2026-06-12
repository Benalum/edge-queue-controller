#!/usr/bin/env bash

stage5p11q_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11Q Companion Review Style Prompt Smoke ==="

  echo
  echo "=== syntax checks ==="
  "$PYBIN" -m py_compile edge_controller.py || ok=0
  node --check frontend/wrapper-ui/app.js || ok=0

  echo
  echo "=== marker checks ==="
  for marker in \
    "STAGE_5P11Q_REVIEW_STYLE_SESSION_START_BEGIN" \
    "_study_normalize_review_mode" \
    "review_mode" \
    "mode must be balanced, new, hard, medium, or easy" \
    "STAGE_5P11Q_COMPANION_REVIEW_STYLE_BEGIN" \
    "stage5p11qSelectedStudyReviewStyle" \
    "stage5p11qReviewStylePrompt" \
    "stage5p11qRouteCompanionReviewStyleCommand" \
    "STAGE_5P11Q_COMPANION_REVIEW_STYLE_ROUTE_HOOK_BEGIN" \
    "Which review style do you want?" \
    "Reply with Balanced, New, Hard, Medium, or Easy"
  do
    if grep -R -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js docs/stage-5p11q-companion-review-style-prompt.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== backend review mode smoke ==="
  "$PYBIN" - <<'PY'
import edge_controller as ec

for mode in ["balanced", "new", "hard", "medium", "easy", "", None, "mixed"]:
    normalized = ec._study_normalize_review_mode(mode)
    assert normalized in {"balanced", "new", "hard", "medium", "easy"}, (mode, normalized)

try:
    ec._study_normalize_review_mode("impossible")
except Exception as exc:
    assert "review_mode must be balanced" in str(exc), str(exc)
else:
    raise AssertionError("invalid review mode did not fail")

print("OK backend review mode normalizer")
PY
  [ "$?" = "0" ] || ok=0

  echo
  echo "=== frontend static checks ==="
  "$PYBIN" - <<'PY'
from pathlib import Path

s = Path("frontend/wrapper-ui/app.js").read_text()

needles = [
    "stage5p11qRouteCompanionReviewStyleCommand(message)",
    "const styleRoute = stage5p11qRouteCompanionReviewStyleCommand(message);",
    "payload.review_mode = reviewMode;",
    "stage5p11qReviewStylePrompt(title + \" — deck \" + deckId)",
    "Which review style do you want?",
    "Review style selected: "
]
for needle in needles:
    assert needle in s, needle

style_pos = s.find("STAGE_5P11Q_COMPANION_REVIEW_STYLE_ROUTE_HOOK_BEGIN")
deck_pos = s.find("STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_BEGIN")
assert style_pos >= 0 and deck_pos >= 0 and style_pos < deck_pos, (style_pos, deck_pos)

print("OK frontend static checks")
PY
  [ "$?" = "0" ] || ok=0

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11q-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /profile /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11q-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11q-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11Q_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11Q_SMOKE_FAIL"
  return 1
}

if stage5p11q_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
