#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bd-companion-hard-clean-visible-workspace-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BD" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "smallest matching panel/card" "$DOC"
grep -Fq "FC-O45-E-BE" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BB Companion clean chat workspace" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BD Companion hard-clean visible workspace" "$APP_JS"
grep -Fq "window.apcCompanionHardCleanWorkspace" "$APP_JS"
grep -Fq "hideSmallestPanels" "$APP_JS"
grep -Fq "companion-hard-clean-hidden" "$APP_JS"
grep -Fq "Chat with your Companion" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"
grep -Fq "Companion auth test" "$APP_JS"
grep -Fq "Companion status" "$APP_JS"
grep -Fq "How this works" "$APP_JS"
grep -Fq "Study phrases" "$APP_JS"
grep -Fq "Companion result reader" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BD Companion hard-clean visible workspace CSS" "$STYLE_CSS"
grep -Fq ".companion-hard-clean-hidden" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

echo "PASS: Stage 16 FC-O45-E-BD Companion hard-clean visible workspace source smoke"
