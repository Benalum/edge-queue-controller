#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
BRIDGE="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion-local-anki-bridge.js"
SESSION="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="$ROOT/docs/stage-17k-x-r2-remove-companion-anki-ui.md"

test -f "$INDEX"
test -f "$BRIDGE"
test -f "$SESSION"
test -f "$DOC"

grep -Fq "stage17kxr2-companion-local-card-ui-removed-20260629" "$INDEX"
grep -Fq "stage17kxr2-local-card-session-ui-removed-20260629" "$INDEX"
grep -Fq "stage17kxr2-companion-local-card-ui-removed-20260629" "$BRIDGE"
grep -Fq "stage17kxr2-local-card-session-ui-removed-20260629" "$SESSION"

grep -Fq "function removePanel()" "$BRIDGE"
grep -Fq "Local card bridge UI removed from Companion." "$BRIDGE"
grep -Fq "card_text_returned_by_bridge: false" "$BRIDGE"
grep -Fq "backend_calls_allowed: false" "$BRIDGE"
grep -Fq "model_calls_allowed: false" "$BRIDGE"
grep -Fq "anki_write_allowed: false" "$BRIDGE"

grep -Fq "function removePanel()" "$SESSION"
grep -Fq "Local card session UI removed from this page." "$SESSION"
grep -Fq "card_text_localstorage_allowed: false" "$SESSION"
grep -Fq "backend_calls_allowed: false" "$SESSION"
grep -Fq "anki_write_allowed: false" "$SESSION"

for forbidden in \
  "Companion local Anki bridge" \
  "Browser-memory bridge only" \
  "This bridge does not return card question text" \
  "Describe current local Anki card shape" \
  "Mount local Anki session controls" \
  "Use current Anki card in Companion study" \
  "Anki read-only session" \
  "Reads Basic-style Anki cards" \
  "Re-select Anki file for this browser session" \
  "Load selected Anki deck into memory" \
  "Reveal answer" \
  "Right</button>" \
  "Wrong</button>" \
  "Stop and clear cards"
do
  if grep -Fq "$forbidden" "$BRIDGE" "$SESSION"; then
    echo "forbidden Companion UI marker remains: $forbidden"
    exit 1
  fi
done

grep -Fq "Remove Companion Local Card UI" "$DOC"
grep -Fq "not a CSS hide" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

if command -v node >/dev/null 2>&1; then
  node --check "$BRIDGE"
  node --check "$SESSION"
fi

echo "PASS: Stage 17K-X-R2 remove Companion local-card UI smoke passed"
