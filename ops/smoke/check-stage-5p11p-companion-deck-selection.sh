#!/usr/bin/env bash

stage5p11p_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"

  echo "=== Stage 5P-11P Companion Deck Selection Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  python3 -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11P_COMPANION_DECK_SELECTION_BEGIN" \
    "STAGE_5P11P_COMPANION_DECK_SELECTION_LOOKS_LIKE_BEGIN" \
    "STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_BEGIN" \
    "stage5p11pFetchDecks" \
    "stage5p11pFormatDeckList" \
    "stage5p11pFindDeckForMessage" \
    "stage5p11pRouteCompanionDeckCommand" \
    "stage5p9aSelectedStudyDeckId" \
    "/api/study/decks" \
    "Study session start" \
    "Select my math deck" \
    "Start math deck"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js docs/stage-5p11p-companion-deck-selection.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== verify command hook order ==="
  python3 - <<'PY'
from pathlib import Path
s = Path("frontend/wrapper-ui/app.js").read_text()

needles = [
    "function stage5p11iLooksLikeStudyCommand",
    "STAGE_5P11P_COMPANION_DECK_SELECTION_BEGIN",
    "async function stage5p11iRouteCompanionStudyCommand",
    "STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_BEGIN",
    "function stage5p11jLooksLikeAnswerAttempt",
    "async function queuedChatSubmit",
]

positions = {}
for needle in needles:
    pos = s.find(needle)
    assert pos >= 0, needle
    positions[needle] = pos

assert positions["STAGE_5P11P_COMPANION_DECK_SELECTION_BEGIN"] < positions["async function stage5p11iRouteCompanionStudyCommand"], positions
assert positions["STAGE_5P11P_COMPANION_DECK_SELECTION_ROUTE_HOOK_BEGIN"] > positions["async function stage5p11iRouteCompanionStudyCommand"], positions
assert positions["async function stage5p11iRouteCompanionStudyCommand"] < positions["async function queuedChatSubmit"], positions

print("OK hook ordering")
PY
  if [ "$?" = "0" ]; then
    echo "OK hook order"
  else
    echo "FAIL hook order"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11p-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /profile /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11p-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11p-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11P_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11P_SMOKE_FAIL"
  return 1
}

if stage5p11p_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
