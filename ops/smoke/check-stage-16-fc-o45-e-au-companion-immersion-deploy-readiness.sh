#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-au-companion-immersion-deploy-readiness.md"
APP_JS="frontend/wrapper-ui/app.js"
STYLE_CSS="frontend/wrapper-ui/styles.css"

test -f "$DOC"
test -f "$APP_JS"
test -f "$STYLE_CSS"

grep -Fq "Stage 16 FC-O45-E-AU" "$DOC"
grep -Fq "Companion Immersion Deploy Readiness" "$DOC"
grep -Fq "NO backend/frontend deploy" "$DOC"
grep -Fq "NO public \`/var/www\` mutation" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AV_DEPLOY_COMPANION_IMMERSION_UI" "$DOC"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode scaffold" "$APP_JS"
grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel source wiring" "$APP_JS"
grep -Fq "window.apcCompanionImmersion" "$APP_JS"
grep -Fq "window.apcCompanionImmersionRuntime" "$APP_JS"
grep -Fq "apcCompanionImmersionObservedFetch" "$APP_JS"

grep -Fq "Stage 16 FC-O45-E-AS Companion Immersion Mode CSS scaffold" "$STYLE_CSS"
grep -Fq "Stage 16 FC-O45-E-AT Companion Immersion visible panel CSS wiring" "$STYLE_CSS"
grep -Fq "#companionImmersionVisiblePanel" "$STYLE_CSS"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS" >/dev/null
fi

echo "PASS: Stage 16 FC-O45-E-AU Companion Immersion deploy readiness smoke"
