#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bm-deploy-companion-delegated-enter-over-tailscale-restricted-path.md"
APP_JS="frontend/wrapper-ui/app.js"

test -f "$DOC"
test -f "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-BM" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BM_DEPLOY_COMPANION_DELEGATED_ENTER_OVER_TAILSCALE_RESTRICTED_PATH" "$DOC"
grep -Fq "apcdeploy@website-edge" "$DOC"
grep -Fq "No QGA package transfer was used" "$DOC"
grep -Fq "/app.js?v=20260624fc045ebm" "$DOC"
grep -Fq "restricted_tailscale_deploy=PASS" "$DOC"
grep -Fq "post_public_verification=PASS" "$DOC"
grep -Fq "post_public_delegated_enter_check=PASS" "$DOC"
grep -Fq "FC_O45_E_BM_DEPLOY_RECORDED" "$DOC"
grep -Fq "mock/no-model" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO model/helper/Ollama call" "$DOC"
grep -Fq "NO service restart" "$DOC"

grep -Fq "Stage 16 FC-O45-E-BL Companion delegated Enter-to-send source" "$APP_JS"
grep -Fq "stage16FcO45EBlCompanionDelegatedEnterToSend" "$APP_JS"
grep -Fq "window.apcCompanionDelegatedEnterToSend" "$APP_JS"
grep -Fq 'target.id !== "queuedChatInput"' "$APP_JS"
grep -Fq 'document.getElementById("queuedChatForm")' "$APP_JS"
grep -Fq 'document.getElementById("queuedChatSendBtn")' "$APP_JS"
grep -Fq "requestSubmit" "$APP_JS"

echo "PASS: Stage 16 FC-O45-E-BM deploy Companion delegated Enter-to-send over Tailscale restricted path smoke"
