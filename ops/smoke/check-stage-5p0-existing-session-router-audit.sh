#!/usr/bin/env bash

stage5p0_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="${STAGE5P0_BASE:-http://127.0.0.1:8787}"
  tmpdir="/tmp/stage5p0-existing-session-router-audit"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-0 Existing Study/Companion Session + Router Audit Smoke ==="
  echo "base=$base"

  echo
  echo "=== git checkpoint ==="
  git status --short
  git rev-parse --short HEAD
  git tag --points-at HEAD || true

  echo
  echo "=== syntax checks ==="
  if node --check frontend/wrapper-ui/app.js; then
    echo "OK wrapper app.js syntax"
  else
    echo "FAIL wrapper app.js syntax"
    ok=0
  fi

  if [ -f frontend/study-ui/app.js ]; then
    if node --check frontend/study-ui/app.js; then
      echo "OK study app.js syntax"
    else
      echo "FAIL study app.js syntax"
      ok=0
    fi
  else
    echo "NOTE frontend/study-ui/app.js not present"
  fi

  if python3 -m py_compile edge_controller.py; then
    echo "OK edge_controller.py syntax"
  else
    echo "FAIL edge_controller.py syntax"
    ok=0
  fi

  echo
  echo "=== required active backend study markers ==="
  required_patterns=(
    "CREATE TABLE IF NOT EXISTS study_decks"
    "CREATE TABLE IF NOT EXISTS study_cards"
    "CREATE TABLE IF NOT EXISTS study_reviews"
    '@app.get("/api/study/decks"'
    '@app.post("/api/study/decks"'
    '@app.get("/api/study/decks/{deck_id}/cards"'
    '@app.post("/api/study/decks/{deck_id}/cards"'
    '@app.post("/api/study/cards/{card_id}/reviews"'
    "review-queue"
    "companion/study/grade"
  )

  for pattern in "${required_patterns[@]}"; do
    if grep -Fq "$pattern" edge_controller.py; then
      echo "OK marker: $pattern"
    else
      echo "FAIL missing marker: $pattern"
      ok=0
    fi
  done

  echo
  echo "=== queued Companion markers ==="
  queued_patterns=(
    "/api/chat/queued"
    "queuedChatSubmit"
    "queuedChatPollJob"
    "queuedChatRenderMessages"
    "STAGE_5O35_COMPANION_UX_BEGIN"
  )

  for pattern in "${queued_patterns[@]}"; do
    if grep -R -Fq "$pattern" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css edge_controller.py; then
      echo "OK marker: $pattern"
    else
      echo "FAIL missing marker: $pattern"
      ok=0
    fi
  done

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
    cat "$tmpdir/public-status.json"
    echo
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    outfile="$tmpdir/${route////_}.html"
    code="$(curl -sS -L -o "$outfile" -w "%{http_code}" "$base$route" 2>> "$tmpdir/routes.err" || true)"
    bytes="$(wc -c < "$outfile" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== audit inventory excerpt ==="
  {
    echo "# Stage 5P-0 Audit Inventory Excerpt"
    echo
    echo "## Study/session/model/router hits"
    grep -RIn --exclude-dir=.git --exclude-dir=.venv --exclude-dir=venv --exclude-dir=node_modules --exclude-dir=__pycache__ \
      --exclude='*.sqlite3' --exclude='*.db' --exclude='*.log' --exclude='*.bak*' \
      -E "study_session|study session|intent|router|model_tier|ollama|pause|resume|correct|incorrect|skip|read answer|/api/chat/queued|queuedChat|deck|card|review-queue|companion/study/grade" \
      edge_controller.py frontend/wrapper-ui frontend/study-ui docs ops 2>/dev/null | sed -n '1,320p' || true
  } > "$tmpdir/audit-inventory-excerpt.md"

  echo "Wrote $tmpdir/audit-inventory-excerpt.md"
  sed -n '1,120p' "$tmpdir/audit-inventory-excerpt.md"

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P0_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P0_SMOKE_FAIL"
  return 1
}

stage5p0_smoke_main "$@"
return 0 2>/dev/null || true
