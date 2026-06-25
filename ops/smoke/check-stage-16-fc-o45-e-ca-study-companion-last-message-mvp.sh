#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

APP_JS="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-e-ca-study-companion-last-message-mvp.md"
BAD_ARCHIVE=".cleanup-archive/stage5j7-wrapper-gateway-reference-cleanup-2026-06-10-191618/frontend/wrapper-ui/app.js"

test -f "$APP_JS"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_START" "$APP_JS"
grep -Fq "APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_END" "$APP_JS"
grep -Fq "Last AI answer" "$APP_JS"
grep -Fq "Check status once" "$APP_JS"
grep -Fq "Copy answer" "$APP_JS"
grep -Fq "Use in Study" "$APP_JS"
grep -Fq "Make flashcards" "$APP_JS"
grep -Fq "Quiz me" "$APP_JS"
grep -Fq "apc.studyCompanion.lastAnswer" "$APP_JS"
grep -Fq "companion.chat" "$APP_JS"

grep -Fq "source-only" "$DOC"
grep -Fq "No runtime was changed" "$DOC"
grep -Fq "CA-R3 removes the accidental marker block" "$DOC"

if [ -f "$BAD_ARCHIVE" ] && grep -Fq "APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP" "$BAD_ARCHIVE"; then
  echo "FAIL: CA marker still present in ignored cleanup archive"
  exit 1
fi

tmp_js="$(mktemp --suffix=.js)"
awk '
  /APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_START/ {flag=1}
  flag {print}
  /APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_END/ {flag=0}
' "$APP_JS" > "$tmp_js"

if grep -Eq 'setInterval|setTimeout|location\.reload|location\.assign|history\.pushState|history\.replaceState|window\.location' "$tmp_js"; then
  echo "FAIL: CA block contains forbidden reload/timer/route-poke behavior"
  cat "$tmp_js"
  rm -f "$tmp_js"
  exit 1
fi

if command -v node >/dev/null 2>&1; then
  node --check "$tmp_js"
else
  echo "node unavailable; skipped JS syntax check"
fi

rm -f "$tmp_js"

echo "PASS stage-16-fc-o45-e-ca-r3 stable Study Companion MVP source smoke"
