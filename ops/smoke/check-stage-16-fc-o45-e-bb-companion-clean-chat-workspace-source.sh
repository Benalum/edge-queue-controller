#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bb-companion-clean-chat-workspace-source.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BB" "$DOC"
grep -Fq "NO live deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "Chat with your Companion" "$DOC"
grep -Fq "Enter-to-send" "$DOC"
grep -Fq "FC-O45-E-BC" "$DOC"

grep -Fq "Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BB Companion clean chat workspace" "$APP_JS"
grep -Fq "window.apcCompanionCleanChatWorkspace" "$APP_JS"
grep -Fq "installEnterToSend" "$APP_JS"
grep -Fq "Chat with your Companion" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"
grep -Fq "companion-clean-hidden" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BB Companion clean chat workspace CSS" "$STYLE_CSS"
grep -Fq ".companion-clean-hidden" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
fi

echo "PASS: Stage 16 FC-O45-E-BB Companion clean chat workspace source smoke"
