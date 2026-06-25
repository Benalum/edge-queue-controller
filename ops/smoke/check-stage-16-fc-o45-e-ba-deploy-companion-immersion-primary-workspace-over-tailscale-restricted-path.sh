#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ba-deploy-companion-immersion-primary-workspace-over-tailscale-restricted-path.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-BA" "$DOC"
grep -Fq "APPROVE_FC_O45_E_BA_DEPLOY_COMPANION_IMMERSION_PRIMARY_WORKSPACE_OVER_TAILSCALE_RESTRICTED_PATH" "$DOC"
grep -Fq "apcdeploy@website-edge" "$DOC"
grep -Fq "No QGA package transfer was used" "$DOC"
grep -Fq "/app.js?v=20260624fc045eba" "$DOC"
grep -Fq "restricted_tailscale_deploy=PASS" "$DOC"
grep -Fq "post_public_verification=PASS" "$DOC"
grep -Fq "FC_O45_E_BA_DEPLOY_RECORDED" "$DOC"
grep -Fq "fallback: qwen2.5:0.5b" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO backend API deploy" "$DOC"
grep -Fq "NO service restart" "$DOC"

grep -Fq "Companion result reader" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AZ Companion Immersion primary workspace placement" "$APP_JS"
grep -Fq "window.apcCompanionImmersionRuntime" "$APP_JS"
grep -Fq "window.apcCompanionImmersionPrimaryWorkspace" "$APP_JS"
grep -Fq "apcCompanionImmersionObservedFetch" "$APP_JS"
grep -Fq "fallback: qwen2.5:0.5b" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring" "$STYLE_CSS"
grep -Fq "Stage 16 FC-O45-E-AZ Companion Immersion primary workspace CSS" "$STYLE_CSS"
grep -Fq "#companionImmersionPrimaryWorkspace" "$STYLE_CSS"

echo "PASS: Stage 16 FC-O45-E-BA deploy Companion Immersion primary workspace over Tailscale restricted path smoke"
