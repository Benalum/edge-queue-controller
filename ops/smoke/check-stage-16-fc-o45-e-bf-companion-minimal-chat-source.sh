#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bf-companion-minimal-chat-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BF" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "Conversation" "$DOC"
grep -Fq "Type a message and press Enter to send." "$DOC"
grep -Fq "FC-O45-E-BG" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BD Companion hard-clean visible workspace" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BF Companion minimal chat source" "$APP_JS"
grep -Fq "window.apcCompanionMinimalChatWorkspace" "$APP_JS"
grep -Fq "hideImmersionChrome" "$APP_JS"
grep -Fq "hideExtraChatCardHeadingAndCopy" "$APP_JS"
grep -Fq "companion-minimal-chat-hidden" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"
grep -Fq "installEnterToSend" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BF Companion minimal chat CSS" "$STYLE_CSS"
grep -Fq ".companion-minimal-chat-hidden" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

echo "PASS: Stage 16 FC-O45-E-BF Companion minimal chat source smoke"
