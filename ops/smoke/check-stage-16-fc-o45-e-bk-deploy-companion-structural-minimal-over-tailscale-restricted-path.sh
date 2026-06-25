#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bk-deploy-companion-structural-minimal-over-tailscale-restricted-path.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BK" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BK_DEPLOY_COMPANION_STRUCTURAL_MINIMAL_OVER_TAILSCALE_RESTRICTED_PATH" "$DOC"
grep -Fq "apcdeploy@website-edge" "$DOC"
grep -Fq "No QGA package transfer was used" "$DOC"
grep -Fq "/app.js?v=20260624fc045ebk" "$DOC"
grep -Fq "restricted_tailscale_deploy=PASS" "$DOC"
grep -Fq "post_public_verification=PASS" "$DOC"
grep -Fq "post_public_structural_render_check=PASS" "$DOC"
grep -Fq "FC_O45_E_BK_DEPLOY_RECORDED" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO backend API deploy" "$DOC"
grep -Fq "NO service restart" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal source" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal early flag" "$APP_JS"
grep -Fq "stage16FcO45EBjR4CompanionStructuralMinimalRuntime" "$APP_JS"
grep -Fq "window.apcCompanionStructuralMinimalWorkspace" "$APP_JS"
grep -Fq "queuedChatMessages" "$APP_JS"
grep -Fq "queuedChatInput" "$APP_JS"
grep -Fq "queuedChatSendBtn" "$APP_JS"
grep -Fq "queuedChatClearBtn" "$APP_JS"
grep -Fq "Type a message and press Enter to send." "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BJ-R4 Companion structural minimal CSS" "$STYLE_CSS"

echo "PASS: Stage 16 FC-O45-E-BK deploy Companion structural minimal over Tailscale restricted path smoke"
