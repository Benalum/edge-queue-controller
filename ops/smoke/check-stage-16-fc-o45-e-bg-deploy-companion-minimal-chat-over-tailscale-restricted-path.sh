#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bg-deploy-companion-minimal-chat-over-tailscale-restricted-path.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BG" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BG_DEPLOY_COMPANION_MINIMAL_CHAT_OVER_TAILSCALE_RESTRICTED_PATH" "$DOC"
grep -Fq "apcdeploy@website-edge" "$DOC"
grep -Fq "No QGA package transfer was used" "$DOC"
grep -Fq "/app.js?v=20260624fc045ebg" "$DOC"
grep -Fq "restricted_tailscale_deploy=PASS" "$DOC"
grep -Fq "post_public_verification=PASS" "$DOC"
grep -Fq "FC_O45_E_BG_DEPLOY_RECORDED" "$DOC"
grep -Fq "Conversation" "$DOC"
grep -Fq "Type a message and press Enter to send." "$DOC"
grep -Fq "Enter sends the message" "$DOC"
grep -Fq "Shift+Enter inserts a newline" "$DOC"
grep -Fq "companion-minimal-chat-hidden" "$DOC"
grep -Fq "fallback: qwen2.5:0.5b" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO backend API deploy" "$DOC"
grep -Fq "NO service restart" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BF Companion minimal chat source" "$APP_JS"
grep -Fq "window.apcCompanionMinimalChatWorkspace" "$APP_JS"
grep -Fq "hideImmersionChrome" "$APP_JS"
grep -Fq "hideExtraChatCardHeadingAndCopy" "$APP_JS"
grep -Fq "companion-minimal-chat-hidden" "$APP_JS"
grep -Fq "installEnterToSend" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"
grep -Fq "fallback: qwen2.5:0.5b" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BF Companion minimal chat CSS" "$STYLE_CSS"
grep -Fq ".companion-minimal-chat-hidden" "$STYLE_CSS"

echo "PASS: Stage 16 FC-O45-E-BG deploy Companion minimal chat over Tailscale restricted path smoke"
