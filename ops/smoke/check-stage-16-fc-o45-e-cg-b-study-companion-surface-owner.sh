#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

APP_JS="frontend/wrapper-ui/app.js"
DOC="docs/stage-16-fc-o45-e-cg-b-study-companion-surface-owner.md"

test -f "$APP_JS"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CA_STUDY_COMPANION_MVP_START" "$APP_JS"
grep -Fq "APC_STAGE16_FC_O45_E_CG_B_SURFACE_OWNER_START" "$APP_JS"
grep -Fq "APC_STAGE16_FC_O45_E_CG_B_SURFACE_OWNER_END" "$APP_JS"
grep -Fq "stage16-fc-o45-e-cg-b-r2" "$APP_JS"
grep -Fq "This panel owns the Companion/Study surface" "$APP_JS"
grep -Fq "MutationObserver" "$APP_JS"
grep -Fq "installFetchSync" "$APP_JS"
grep -Fq "apcStudyCompanionMvpSync" "$APP_JS"
grep -Fq "adoptVisibleLegacyState" "$APP_JS"
grep -Fq "/api/chat/queued" "$APP_JS"
grep -Fq "apc.studyCompanion.lastAnswer" "$APP_JS"
grep -Fq "apc.studyCompanion.lastPrompt" "$APP_JS"
grep -Fq "apc.studyCompanion.lastJobId" "$APP_JS"
grep -Fq "apc.studyCompanion.status" "$APP_JS"
grep -Fq "Last AI answer" "$APP_JS"
grep -Fq "Check status once" "$APP_JS"
grep -Fq "Copy answer" "$APP_JS"
grep -Fq "Use in Study" "$APP_JS"
grep -Fq "Make flashcards" "$APP_JS"
grep -Fq "Quiz me" "$APP_JS"

grep -Fq "source-only" "$DOC"
grep -Fq "browser job 573" "$DOC"
grep -Fq "CG-B-R2 appends a surface-owner override block" "$DOC"
grep -Fq "No runtime was changed" "$DOC"

tmp_js="$(mktemp --suffix=.js)"
awk '
  /APC_STAGE16_FC_O45_E_CG_B_SURFACE_OWNER_START/ {flag=1}
  flag {print}
  /APC_STAGE16_FC_O45_E_CG_B_SURFACE_OWNER_END/ {flag=0}
' "$APP_JS" > "$tmp_js"

if grep -Eq 'setInterval|setTimeout|location\.reload|location\.assign|history\.pushState|history\.replaceState|window\.location' "$tmp_js"; then
  echo "FAIL: CG-B owner block contains forbidden reload/timer/route-poke behavior"
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

echo "PASS stage-16-fc-o45-e-cg-b Study Companion surface owner source smoke"
